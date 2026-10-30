<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<script lang="ts">
	import 'maplibre-gl/dist/maplibre-gl.css';
	import { onMount } from 'svelte';
	import { LngLatBounds, Map as BanDo, NavigationControl, type GeoJSONSource, type MapMouseEvent } from 'maplibre-gl';
	import { batDauDangNhap, dangXuat, nguoiDung, tokenHienTai } from '#lib/dang-nhap.ts';
	import { goiGraphql, LoiNghiepVu } from '#lib/graphql.ts';
	import { dienTichHa } from '#lib/dien-tich.ts';
	import ChiTietLo from '#lib/ChiTietLo.svelte';

	type Polygon = { type: 'Polygon'; coordinates: [number, number][][] };
	type Lo = {
		rowId: string;
		ten: string;
		dienTichHa: string;
		dienTichKhaiBaoHa: string;
		namTrong: number | null;
		ranhGioi: Polygon;
		carbonXaVienByXaVienId: { hoTen: string } | null;
	};
	type XaVien = { rowId: string; hoTen: string; maXaVien: string };
	type KhoiTinChi = { rowId: string; soLuong: number; maTrongNuoc: string; seriTu: string; seriDen: string };

	// Cùng truy vấn với tests/e2e/web.hurl (ca "truy vấn trang chính") – sửa ở đây thì sửa cả ở đó.
	// orderBy chỉ có trên cột có index; tên lô sắp xếp phía trình duyệt.
	const DU_LIEU = `{
		allCarbonLoDats(condition: { trangThai: "hoat_dong" }) {
			nodes { rowId ten dienTichHa dienTichKhaiBaoHa namTrong ranhGioi carbonXaVienByXaVienId { hoTen } }
		}
		allCarbonXaViens(orderBy: MA_XA_VIEN_ASC) { nodes { rowId hoTen maXaVien } }
		allCarbonCanBoHtxes { totalCount }
		allCarbonKhoiTinChis { nodes { rowId soLuong maTrongNuoc seriTu seriDen } }
	}`;
	const DANG_KY = `mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) {
		carbonDangKyLoDat(input: { xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam }) { result }
	}`;

	const token = tokenHienTai();
	const nd = token ? nguoiDung(token) : null;
	let banDo: BanDo | undefined;
	let khungBanDo: HTMLDivElement;

	let lo = $state<Lo[]>([]);
	let xaVien = $state<XaVien[]>([]);
	let loiTai = $state('');
	let dangVe = $state(false);
	let dinh = $state<[number, number][]>([]);
	let form = $state({ xaVienId: '', ten: '', dienTich: '', namTrong: '' });
	let loi = $state<{ thongBao: string; goiY?: string } | null>(null);
	let thanhCong = $state('');
	let dangGui = $state(false);
	let laCanBo = $state(false);
	let vi = $state<KhoiTinChi[]>([]);
	let loChon = $state<Lo | null>(null);
	let lopNdvi = $state<string | null>(null);

	const dienTichVe = $derived(dienTichHa(dinh));
	const lechKhaiBao = $derived.by(() => {
		const k = Number(form.dienTich.replace(',', '.'));
		return dinh.length >= 3 && k > 0 ? Math.abs(k - dienTichVe) / dienTichVe : null;
	});

	function veLai() {
		const nguon = banDo?.getSource<GeoJSONSource>('lo');
		nguon?.setData({
			type: 'FeatureCollection',
			features: lo.map((l) => ({
				type: 'Feature',
				geometry: l.ranhGioi,
				properties: { id: l.rowId, ten: l.ten, chon: l.rowId === loChon?.rowId }
			}))
		});
		const nhap = banDo?.getSource<GeoJSONSource>('nhap');
		const vong = dinh.length >= 3 ? [...dinh, dinh[0]] : dinh;
		nhap?.setData({
			type: 'FeatureCollection',
			features: [
				...(dinh.length >= 3
					? [{ type: 'Feature' as const, geometry: { type: 'Polygon' as const, coordinates: [vong] }, properties: {} }]
					: []),
				...(dinh.length >= 2
					? [{ type: 'Feature' as const, geometry: { type: 'LineString' as const, coordinates: vong }, properties: {} }]
					: []),
				...dinh.map((d) => ({ type: 'Feature' as const, geometry: { type: 'Point' as const, coordinates: d }, properties: {} }))
			]
		});
	}

	async function taiDuLieu() {
		if (!token) return;
		try {
			const d = await goiGraphql<{
				allCarbonLoDats: { nodes: Lo[] };
				allCarbonXaViens: { nodes: XaVien[] };
				allCarbonCanBoHtxes: { totalCount: number };
				allCarbonKhoiTinChis: { nodes: KhoiTinChi[] };
			}>(token, DU_LIEU);
			vi = d.allCarbonKhoiTinChis.nodes.sort((a, b) => a.seriTu.localeCompare(b.seriTu));
			lo = d.allCarbonLoDats.nodes.sort((a, b) => a.ten.localeCompare(b.ten, 'vi'));
			xaVien = d.allCarbonXaViens.nodes;
			// Nút yêu cầu đo / duyệt chỉ hiện cho cán bộ hợp tác xã và quản trị; CSDL vẫn kiểm lại (UC011)
			laCanBo = d.allCarbonCanBoHtxes.totalCount > 0 || (nd?.vai.includes('quan_tri') ?? false);
			if (!form.xaVienId && xaVien.length) form.xaVienId = xaVien[0].rowId;
			loiTai = '';
			veLai();
		} catch (e) {
			loiTai = (e as Error).message;
		}
	}

	function chonLo(l: Lo) {
		loChon = l;
		xemLop(null);
		veLai();
		const b = new LngLatBounds();
		for (const d of l.ranhGioi.coordinates[0]) b.extend(d);
		banDo?.fitBounds(b, { padding: 60, maxZoom: 16 });
	}

	function boChon() {
		loChon = null;
		xemLop(null);
		veLai();
	}

	/** Lớp NDVI (COG trong S3 nền tảng) qua TiTiler /tiles; thang màu đỏ–vàng–xanh, NDVI 0 → 1. */
	function xemLop(cog: string | null) {
		lopNdvi = cog;
		const b = banDo;
		if (!b?.isStyleLoaded()) return;
		if (b.getLayer('ndvi')) b.removeLayer('ndvi');
		if (b.getSource('ndvi')) b.removeSource('ndvi');
		if (!cog) return;
		const q = new URLSearchParams({ url: cog, rescale: '0,1', colormap_name: 'rdylgn' });
		b.addSource('ndvi', {
			type: 'raster',
			tiles: [`${location.origin}/tiles/cog/tiles/WebMercatorQuad/{z}/{x}/{y}.png?${q}`],
			tileSize: 256,
			attribution: 'Chứa dữ liệu Copernicus Sentinel đã qua xử lý'
		});
		b.addLayer({ id: 'ndvi', type: 'raster', source: 'ndvi', paint: { 'raster-opacity': 0.85 } }, 'lo-vien');
	}

	function batDauVe() {
		boChon();
		dangVe = true;
		dinh = [];
		loi = null;
		thanhCong = '';
		veLai();
	}

	function huyVe() {
		dangVe = false;
		dinh = [];
		loi = null;
		veLai();
	}

	async function dangKy(e: SubmitEvent) {
		e.preventDefault();
		if (!token) return;
		loi = null;
		dangGui = true;
		try {
			const r: Polygon = { type: 'Polygon', coordinates: [[...dinh, dinh[0]]] };
			await goiGraphql(token, DANG_KY, {
				xv: form.xaVienId,
				ten: form.ten,
				r,
				dt: form.dienTich.replace(',', '.'),
				nam: form.namTrong ? Number(form.namTrong) : null
			});
			thanhCong = `Đã đăng ký lô "${form.ten}".`;
			form = { ...form, ten: '', dienTich: '', namTrong: '' };
			dangVe = false;
			dinh = [];
			await taiDuLieu();
		} catch (e) {
			loi =
				e instanceof LoiNghiepVu ? { thongBao: e.message, goiY: e.goiY } : { thongBao: (e as Error).message };
		} finally {
			dangGui = false;
		}
	}

	onMount(() => {
		// Nền OpenStreetMap (dữ liệu ODbL, ghi nguồn); vùng mẫu rừng ngập mặn ven biển Mũi Cà Mau.
		banDo = new BanDo({
			container: khungBanDo,
			style: {
				version: 8,
				sources: {
					osm: {
						type: 'raster',
						tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
						tileSize: 256,
						attribution: '© Những người đóng góp OpenStreetMap'
					}
				},
				layers: [{ id: 'osm', type: 'raster', source: 'osm' }]
			},
			center: [104.77, 8.625],
			zoom: 13,
			// Tile ảnh của nền tảng (/tiles) cần JWT như mọi API qua gateway
			transformRequest: (url) =>
				token && url.startsWith(`${location.origin}/tiles/`)
					? { url, headers: { Authorization: `Bearer ${token.access_token}` } }
					: { url }
		});
		banDo.addControl(new NavigationControl(), 'top-right');
		banDo.on('load', () => {
			const b = banDo!;
			b.addSource('lo', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });
			b.addLayer({
				id: 'lo-nen',
				type: 'fill',
				source: 'lo',
				paint: { 'fill-color': '#2d6a4f', 'fill-opacity': ['case', ['get', 'chon'], 0.1, 0.35] }
			});
			b.addLayer({
				id: 'lo-vien',
				type: 'line',
				source: 'lo',
				paint: { 'line-color': ['case', ['get', 'chon'], '#e76f51', '#1b4332'], 'line-width': ['case', ['get', 'chon'], 3, 2] }
			});
			b.addLayer({
				id: 'lo-ten',
				type: 'symbol',
				source: 'lo',
				layout: { 'text-field': ['get', 'ten'], 'text-size': 12 },
				paint: { 'text-color': '#081c15', 'text-halo-color': '#fff', 'text-halo-width': 1.5 }
			});
			b.addSource('nhap', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });
			b.addLayer({
				id: 'nhap-nen',
				type: 'fill',
				source: 'nhap',
				filter: ['==', '$type', 'Polygon'],
				paint: { 'fill-color': '#e9c46a', 'fill-opacity': 0.4 }
			});
			b.addLayer({
				id: 'nhap-vien',
				type: 'line',
				source: 'nhap',
				filter: ['==', '$type', 'LineString'],
				paint: { 'line-color': '#b5651d', 'line-width': 2, 'line-dasharray': [2, 1] }
			});
			b.addLayer({
				id: 'nhap-dinh',
				type: 'circle',
				source: 'nhap',
				filter: ['==', '$type', 'Point'],
				paint: { 'circle-radius': 5, 'circle-color': '#b5651d', 'circle-stroke-color': '#fff', 'circle-stroke-width': 2 }
			});
			taiDuLieu();
		});
		banDo.on('click', 'lo-nen', (e) => {
			if (dangVe) return;
			const id = e.features?.[0]?.properties?.id;
			const l = lo.find((x) => x.rowId === id);
			if (l) chonLo(l);
		});
		banDo.on('click', (e: MapMouseEvent) => {
			if (!dangVe) return;
			dinh = [...dinh, [Number(e.lngLat.lng.toFixed(7)), Number(e.lngLat.lat.toFixed(7))]];
			veLai();
		});
		return () => banDo?.remove();
	});
</script>

<header>
	<strong>CarbonFarm OS</strong>
	{#if nd}
		<span>Xin chào, <b>{nd.ten}</b></span>
		<button onclick={dangXuat}>Đăng xuất</button>
	{:else}
		<button onclick={batDauDangNhap}>Đăng nhập</button>
	{/if}
</header>

<main>
	<div class="ban-do" class:dang-ve={dangVe} bind:this={khungBanDo} aria-label="Bản đồ lô đất rừng ngập mặn"></div>

	<aside>
		{#if !nd}
			<p>Đăng nhập để xem và đăng ký lô đất của hợp tác xã.</p>
		{:else if loiTai}
			<p role="alert" class="loi">{loiTai}</p>
		{:else if loChon && token}
			<ChiTietLo
				{token}
				lo={loChon}
				{laCanBo}
				lopDangXem={lopNdvi}
				onXemLop={xemLop}
				onThayDoi={taiDuLieu}
				onDong={boChon}
			/>
		{:else if dangVe}
			<h2>Đăng ký lô mới</h2>
			<p class="huong-dan">Bấm lên bản đồ để đặt từng góc lô, theo một chiều quanh ranh giới. Cần ít nhất 3 điểm.</p>
			<p>
				Đã đặt <b>{dinh.length}</b> điểm{#if dinh.length >= 3}, diện tích vẽ ≈ <b>{dienTichVe.toFixed(2)} ha</b>{/if}.
				{#if dinh.length}<button type="button" class="phu" onclick={() => ((dinh = dinh.slice(0, -1)), veLai())}>Bỏ điểm cuối</button>{/if}
			</p>
			<form onsubmit={dangKy}>
				<label>
					Xã viên
					<select bind:value={form.xaVienId} required>
						{#each xaVien as x (x.rowId)}<option value={x.rowId}>{x.maXaVien} · {x.hoTen}</option>{/each}
					</select>
				</label>
				<label>Tên lô <input bind:value={form.ten} required minlength="2" maxlength="120" /></label>
				<label>
					Diện tích theo giấy tờ (ha)
					<input bind:value={form.dienTich} required inputmode="decimal" placeholder="ví dụ 8,9" />
				</label>
				{#if lechKhaiBao !== null && lechKhaiBao > 0.1}
					<p class="canh-bao">
						Lệch {(lechKhaiBao * 100).toFixed(0)} % so với diện tích vẽ – hệ thống chỉ chấp nhận lệch tối đa 10 %.
					</p>
				{/if}
				<label>
					Năm trồng / phục hồi
					<input bind:value={form.namTrong} inputmode="numeric" placeholder="ví dụ 2019" />
				</label>
				{#if loi}
					<div role="alert" class="loi">
						<b>{loi.thongBao}</b>
						{#if loi.goiY}<br />{loi.goiY}{/if}
					</div>
				{/if}
				<div class="nut">
					<button type="submit" disabled={dinh.length < 3 || dangGui}>{dangGui ? 'Đang gửi…' : 'Đăng ký'}</button>
					<button type="button" class="phu" onclick={huyVe}>Hủy</button>
				</div>
			</form>
		{:else}
			{#if vi.length}
				<section class="vi" aria-label="Ví tín chỉ hợp tác xã">
					<h2>Ví tín chỉ: {vi.reduce((t, k) => t + k.soLuong, 0)} tín chỉ</h2>
					<ul>
						{#each vi as k (k.rowId)}
							<li><b>{k.soLuong}</b> · <small>{k.seriTu} → {k.seriDen}</small></li>
						{/each}
					</ul>
				</section>
			{/if}
			<h2>Lô đang hoạt động ({lo.length})</h2>
			{#if thanhCong}<p class="ok">{thanhCong}</p>{/if}
			<ul>
				{#each lo as l (l.rowId)}
					<li>
						<button type="button" class="lo" onclick={() => chonLo(l)}>
							<b>{l.ten}</b>
							<span>{l.carbonXaVienByXaVienId?.hoTen ?? ''}</span>
							<span>{l.dienTichHa} ha{#if l.namTrong} · trồng {l.namTrong}{/if}</span>
						</button>
					</li>
				{:else}
					<li>Chưa có lô nào bạn được xem.</li>
				{/each}
			</ul>
			{#if xaVien.length}
				<button onclick={batDauVe}>+ Đăng ký lô mới</button>
			{/if}
		{/if}
	</aside>
</main>

<style>
	:global(:root) {
		color-scheme: light;
	}
	:global(body) {
		margin: 0;
		font-family: system-ui, sans-serif;
		background: #f4f7f2;
		color: #1b2b22;
	}
	header {
		display: flex;
		gap: 1rem;
		align-items: center;
		padding: 0.75rem 1rem;
		background: #1b4332;
		color: #fff;
	}
	header strong {
		flex: 1;
	}
	main {
		display: grid;
		grid-template-columns: 1fr 26rem;
		gap: 1rem;
		padding: 1rem;
	}
	@media (max-width: 800px) {
		main {
			grid-template-columns: 1fr;
		}
	}
	.ban-do {
		height: 75vh;
		border-radius: 8px;
		background: #dfe8dc;
	}
	.ban-do.dang-ve :global(canvas) {
		cursor: crosshair;
	}
	.vi {
		margin-bottom: 1rem;
		padding: 0.6rem 0.7rem;
		border-radius: 8px;
		background: #1b4332;
		color: #fff;
	}
	.vi ul {
		margin: 0;
		font-size: 0.85rem;
		overflow-wrap: anywhere;
	}
	aside h2 {
		margin: 0 0 0.5rem;
		font-size: 1.1rem;
	}
	ul {
		list-style: none;
		padding: 0;
		margin: 0 0 1rem;
	}
	li + li {
		margin-top: 0.4rem;
	}
	.lo {
		display: grid;
		width: 100%;
		text-align: left;
		background: #fff;
		border: 1px solid #cfdccb;
		color: #1b2b22;
	}
	.lo span {
		font-size: 0.85rem;
		color: #40594a;
	}
	form {
		display: grid;
		gap: 0.6rem;
	}
	label {
		display: grid;
		gap: 0.2rem;
		font-size: 0.9rem;
	}
	input,
	select {
		font: inherit;
		padding: 0.35rem 0.5rem;
		border: 1px solid #b7c9b2;
		border-radius: 6px;
		background: #fff;
		color: #1b2b22;
	}
	.huong-dan {
		font-size: 0.9rem;
		color: #40594a;
	}
	.loi {
		padding: 0.5rem 0.7rem;
		border-radius: 6px;
		background: #fde2e1;
		color: #7a1c17;
	}
	.canh-bao {
		margin: 0;
		font-size: 0.85rem;
		color: #8a4b00;
	}
	.ok {
		color: #1b4332;
		font-weight: 600;
	}
	.nut {
		display: flex;
		gap: 0.5rem;
	}
	button {
		font: inherit;
		padding: 0.35rem 0.9rem;
		border: 0;
		border-radius: 6px;
		background: #95d5b2;
		color: #1b4332;
		cursor: pointer;
	}
	button:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}
	button.phu {
		background: #e3ebe0;
	}
</style>
