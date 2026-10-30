<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<script lang="ts">
	import 'maplibre-gl/dist/maplibre-gl.css';
	import { onMount } from 'svelte';
	import { LngLatBounds, Map as BanDo, Marker, NavigationControl, ScaleControl, type GeoJSONSource, type MapMouseEvent } from 'maplibre-gl';
	import { dangXuat, nguoiDung, tokenHienTai } from '#lib/dang-nhap.ts';
	import { kieuBanDo, NEN, tam, themLopLo } from '#lib/ban-do.ts';
	import TrangGioiThieu from '#lib/TrangGioiThieu.svelte';
	import { goiGraphql, LoiNghiepVu } from '#lib/graphql.ts';
	import { dienTichHa } from '#lib/dien-tich.ts';
	import ChiTietLo from '#lib/ChiTietLo.svelte';
	import ViTinChi from '#lib/ViTinChi.svelte';

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
	type KhoiTinChi = {
		rowId: string;
		soLuong: number;
		maTrongNuoc: string;
		seriTu: string;
		seriDen: string;
		hopTacXaId: string;
	};

	// Cùng truy vấn với tests/e2e/web.hurl (ca "truy vấn trang chính") – sửa ở đây thì sửa cả ở đó.
	// orderBy chỉ có trên cột có index; tên lô sắp xếp phía trình duyệt.
	const DU_LIEU = `{
		allCarbonLoDats(condition: { trangThai: "hoat_dong" }) {
			nodes { rowId ten dienTichHa dienTichKhaiBaoHa namTrong ranhGioi carbonXaVienByXaVienId { hoTen } }
		}
		allCarbonXaViens(orderBy: MA_XA_VIEN_ASC) { nodes { rowId hoTen maXaVien } }
		allCarbonCanBoHtxes { totalCount }
		allCarbonKhoiTinChis { nodes { rowId soLuong maTrongNuoc seriTu seriDen hopTacXaId } }
		allCarbonHopTacXas { nodes { ten } }
	}`;
	const DANG_KY = `mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) {
		carbonDangKyLoDat(input: { xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam }) { result }
	}`;

	const token = tokenHienTai();
	const nd = token ? nguoiDung(token) : null;
	let banDo: BanDo | undefined;
	let khungBanDo = $state<HTMLDivElement>();
	let nhanLo: Marker[] = [];

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
	let tenHtx = $state('');
	let timLo = $state('');
	const loLoc = $derived(lo.filter((l) => l.ten.toLocaleLowerCase('vi').includes(timLo.trim().toLocaleLowerCase('vi'))));
	const tongHa = $derived(lo.reduce((t, l) => t + Number(l.dienTichHa), 0));
	const tongVi = $derived(vi.reduce((t, k) => t + k.soLuong, 0));

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
		// Nhãn tên lô đặt ở tâm lô
		nhanLo.forEach((m) => m.remove());
		nhanLo = banDo
			? lo.map((l) => {
					const el = document.createElement('div');
					el.className = 'nhan-lo' + (l.rowId === loChon?.rowId ? ' chon' : '');
					el.append(l.ten);
					const ha = document.createElement('small');
					ha.textContent = `${Number(l.dienTichHa).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ha`;
					el.append(ha);
					return new Marker({ element: el }).setLngLat(tam(l.ranhGioi)).addTo(banDo!);
				})
			: [];
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
				allCarbonHopTacXas: { nodes: { ten: string }[] };
			}>(token, DU_LIEU);
			tenHtx = d.allCarbonHopTacXas.nodes.map((h) => h.ten).join(', ');
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
		banDo?.fitBounds(b, { padding: 80, maxZoom: 15 });
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
		b.addLayer({ id: 'ndvi', type: 'raster', source: 'ndvi', paint: { 'raster-opacity': 0.85 } }, 'lo-nen');
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
		if (!nd || !khungBanDo) return;
		banDo = new BanDo({
			container: khungBanDo,
			style: kieuBanDo(),
			bounds: NEN.toaDo[0].concat(NEN.toaDo[2]) as [number, number, number, number],
			attributionControl: { compact: true, customAttribution: NEN.ghiNguon },
			dragRotate: false,
			// Tile ảnh của nền tảng (/tiles) cần JWT như mọi API qua gateway
			transformRequest: (url) =>
				token && url.startsWith(`${location.origin}/tiles/`)
					? { url, headers: { Authorization: `Bearer ${token.access_token}` } }
					: { url }
		});
		banDo.addControl(new NavigationControl({ showCompass: false }), 'top-right');
		banDo.addControl(new ScaleControl({ unit: 'metric', maxWidth: 140 }), 'bottom-left');
		banDo.on('load', () => {
			const b = banDo!;
			themLopLo(b);
			// Ranh giới đang vẽ: nét đứt màu dữ liệu, mỗi góc một chấm
			b.addSource('nhap', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });
			b.addLayer({
				id: 'nhap-nen',
				type: 'fill',
				source: 'nhap',
				filter: ['==', '$type', 'Polygon'],
				paint: { 'fill-color': '#ecba82', 'fill-opacity': 0.2 }
			});
			b.addLayer({
				id: 'nhap-vien',
				type: 'line',
				source: 'nhap',
				filter: ['==', '$type', 'LineString'],
				paint: { 'line-color': '#ecba82', 'line-width': 3, 'line-dasharray': [2, 1] }
			});
			b.addLayer({
				id: 'nhap-dinh',
				type: 'circle',
				source: 'nhap',
				filter: ['==', '$type', 'Point'],
				paint: { 'circle-radius': 5, 'circle-color': '#ffffff', 'circle-stroke-color': '#024f46', 'circle-stroke-width': 2.5 }
			});
			taiDuLieu();
		});
		banDo.on('click', 'lo-nen', (e) => {
			if (dangVe) return;
			const id = e.features?.[0]?.properties?.id;
			const l = lo.find((x) => x.rowId === id);
			if (l) chonLo(l);
		});
		banDo.on('mouseenter', 'lo-nen', () => !dangVe && (banDo!.getCanvas().style.cursor = 'pointer'));
		banDo.on('mouseleave', 'lo-nen', () => !dangVe && (banDo!.getCanvas().style.cursor = ''));
		banDo.on('click', (e: MapMouseEvent) => {
			if (!dangVe) return;
			dinh = [...dinh, [Number(e.lngLat.lng.toFixed(7)), Number(e.lngLat.lat.toFixed(7))]];
			veLai();
		});
		return () => {
			nhanLo.forEach((m) => m.remove());
			banDo?.remove();
		};
	});
</script>

{#if !nd}
	<TrangGioiThieu />
{:else}
	<div class="ung-dung">
		<header class="thanh-tren">
			<a class="ten" href="/">CarbonFarm OS</a>
			<label class="tim">
				<span class="an">Tìm lô</span>
				<svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="8.5" cy="8.5" r="5.5" /><path d="m13 13 4 4" /></svg>
				<input type="search" bind:value={timLo} placeholder="Tìm lô theo tên" autocomplete="off" />
			</label>
			<div class="tai-khoan">
				<a href="/kiem-chung">Kiểm chứng</a>
				<span class="nguoi" title={nd.ten}>{nd.ten.trim().charAt(0).toLocaleUpperCase('vi')}</span>
				<button class="chu" onclick={dangXuat}>Đăng xuất</button>
			</div>
		</header>

		<nav class="ben" aria-label="Lô đất của hợp tác xã">
			<p class="nhom">Hợp tác xã</p>
			<p class="htx">{tenHtx || 'Hợp tác xã'}</p>
			<p class="nhom">Lô đang hoạt động · {lo.length}</p>
			<ul>
				{#each loLoc as l (l.rowId)}
					<li>
						<button class:chon={l.rowId === loChon?.rowId} onclick={() => chonLo(l)}>
							<span>{l.ten}</span>
							<span class="so">{Number(l.dienTichHa).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ha</span>
						</button>
					</li>
				{:else}
					<li class="trong">{timLo ? 'Không có lô nào khớp' : 'Chưa có lô nào bạn được xem'}</li>
				{/each}
			</ul>
			{#if xaVien.length && !dangVe}
				<button class="nut nhat nho them" onclick={batDauVe}>+ Đăng ký lô mới</button>
			{/if}
			<button class="vi-nho" onclick={boChon}>
				<span class="nhom">Ví tín chỉ</span>
				<span class="so-lon">{tongVi}</span>
				<span class="xem">Xem ví và lệnh bán</span>
			</button>
		</nav>

		<main class="to">
			<div class="khung-ban-do">
				<div class="ban-do" class:dang-ve={dangVe} bind:this={khungBanDo} aria-label="Bản đồ lô đất, ảnh Sentinel-2"></div>
				{#if dangVe}
					<p class="goi-y-ve">Bấm lên bản đồ để đặt từng góc lô, đủ 3 góc trở lên</p>
				{/if}
			</div>

			<section class="bang" aria-live="polite">
				{#if loiTai}
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
					<div class="vet">
						<button class="chu" onclick={huyVe}>Lô đất</button><span>/</span>
					</div>
					<h1>Đăng ký lô mới</h1>
					<dl class="so-lieu">
						<div><dt>Góc đã đặt</dt><dd>{dinh.length}</dd></div>
						<div><dt>Diện tích vẽ</dt><dd>{dinh.length >= 3 ? `${dienTichVe.toFixed(2)} ha` : '–'}</dd></div>
					</dl>
					{#if dinh.length}
						<button type="button" class="chu" onclick={() => ((dinh = dinh.slice(0, -1)), veLai())}>Bỏ góc vừa đặt</button>
					{/if}
					<form onsubmit={dangKy}>
						<label class="o-nhap">
							Xã viên
							<select bind:value={form.xaVienId} required>
								{#each xaVien as x (x.rowId)}<option value={x.rowId}>{x.maXaVien} · {x.hoTen}</option>{/each}
							</select>
						</label>
						<label class="o-nhap">Tên lô <input bind:value={form.ten} required minlength="2" maxlength="120" /></label>
						<div class="hang">
							<label class="o-nhap">
								Diện tích trên giấy tờ (ha)
								<input bind:value={form.dienTich} required inputmode="decimal" placeholder="8,9" />
							</label>
							<label class="o-nhap">
								Năm trồng
								<input bind:value={form.namTrong} inputmode="numeric" placeholder="2019" />
							</label>
						</div>
						{#if lechKhaiBao !== null && lechKhaiBao > 0.1}
							<p class="canh-bao">Lệch {(lechKhaiBao * 100).toFixed(0)} % so với diện tích vẽ; hệ thống chỉ nhận lệch tối đa 10 %.</p>
						{/if}
						{#if loi}
							<div role="alert" class="loi"><b>{loi.thongBao}</b>{#if loi.goiY}<br />{loi.goiY}{/if}</div>
						{/if}
						<button class="nut rong" type="submit" disabled={dinh.length < 3 || dangGui}>{dangGui ? 'Đang gửi…' : 'Đăng ký lô'}</button>
						<button class="chu giua" type="button" onclick={huyVe}>Huỷ</button>
					</form>
				{:else}
					<p class="nhom">Tổng quan</p>
					<h1>{tenHtx || 'Hợp tác xã'}</h1>
					<dl class="so-lieu">
						<div><dt>Lô đang hoạt động</dt><dd>{lo.length}</dd></div>
						<div><dt>Diện tích theo ranh giới</dt><dd>{tongHa.toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ha</dd></div>
						<div><dt>Tín chỉ trong ví</dt><dd>{tongVi}</dd></div>
					</dl>
					{#if thanhCong}<p class="thanh-cong">{thanhCong}</p>{/if}
					<p class="goi-y">Chọn một lô trên bản đồ hoặc ở cột trái để xem kết quả đo và duyệt.</p>
					{#if token}
						<ViTinChi {token} {laCanBo} {vi} onThayDoi={taiDuLieu} />
					{/if}
				{/if}
			</section>
		</main>
	</div>
{/if}

<style>
	.ung-dung {
		display: grid;
		grid-template-columns: 260px minmax(0, 1fr);
		grid-template-rows: 72px minmax(0, 1fr);
		height: 100dvh;
		background: var(--giay);
		font-size: 0.9375rem;
	}
	.thanh-tren {
		grid-column: 1 / -1;
		display: grid;
		grid-template-columns: 260px 1fr auto;
		align-items: center;
		padding-right: 20px;
	}
	.ten {
		padding-left: 24px;
		color: var(--muc);
		font: 600 1.375rem var(--serif);
		letter-spacing: -0.02em;
		text-decoration: none;
	}
	.tim {
		position: relative;
		justify-self: center;
		width: min(520px, 100%);
	}
	.tim svg {
		position: absolute;
		left: 16px;
		top: 50%;
		width: 18px;
		height: 18px;
		transform: translateY(-50%);
		fill: none;
		stroke: var(--mo);
		stroke-width: 1.8;
		stroke-linecap: round;
	}
	.tim input {
		width: 100%;
		height: 44px;
		padding: 0 16px 0 44px;
		border: 2px solid transparent;
		border-radius: 999px;
		background: #fff;
		color: var(--muc);
		font: 400 0.9375rem var(--sans);
	}
	.tim input:focus {
		outline: none;
		border-color: var(--teal);
	}
	.tai-khoan {
		display: flex;
		align-items: center;
		gap: 18px;
		color: var(--mo);
	}
	.tai-khoan a {
		color: var(--muc);
		font-weight: 500;
		text-decoration: none;
	}
	.nguoi {
		display: grid;
		place-items: center;
		width: 40px;
		height: 40px;
		border-radius: 50%;
		background: var(--teal);
		color: #fff;
		font: 600 1rem var(--serif);
	}
	.chu {
		min-height: 32px;
		padding: 0;
		border: 0;
		background: none;
		color: var(--teal);
		font: 500 0.9375rem var(--sans);
		text-decoration: underline;
		text-underline-offset: 0.25em;
		cursor: pointer;
	}
	.chu:hover {
		color: var(--teal-dam);
	}
	.chu.giua {
		justify-self: center;
	}

	.ben {
		display: flex;
		flex-direction: column;
		gap: 6px;
		padding: 8px 16px 16px 24px;
		overflow-y: auto;
	}
	.htx {
		margin-bottom: 20px;
		color: var(--muc);
		font: 600 1.25rem/1.25 var(--serif);
	}
	.nhom {
		margin: 0;
		color: var(--mo);
		font-size: 0.8125rem;
		font-weight: 500;
	}
	.ben ul {
		display: grid;
		gap: 6px;
		margin: 6px 0 0;
		padding: 0;
		list-style: none;
	}
	.ben li button {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 8px;
		width: 100%;
		min-height: 48px;
		padding: 0 16px;
		border: 0;
		border-radius: 14px;
		background: #fff;
		color: var(--muc);
		font: 500 0.9375rem var(--sans);
		text-align: left;
		cursor: pointer;
		transition: background-color 0.15s var(--de);
	}
	.ben li button:hover {
		background: #fbfbfa;
	}
	.ben li button.chon {
		background: var(--teal);
		color: #fff;
	}
	.ben li button.chon .so {
		color: #b9d6d0;
	}
	.so {
		color: var(--mo);
		font-weight: 400;
	}
	.trong {
		padding: 8px 4px;
		color: var(--mo);
	}
	.them {
		margin-top: 8px;
	}
	.vi-nho {
		display: grid;
		gap: 4px;
		margin-top: auto;
		padding: 20px;
		border: 0;
		border-radius: 20px;
		background: var(--dao);
		color: #fff;
		font: inherit;
		text-align: left;
		cursor: pointer;
	}
	.vi-nho .nhom {
		color: #b5b4ae;
	}
	.so-lon {
		font: 600 2.5rem/1.05 var(--serif);
		letter-spacing: -0.02em;
	}
	.xem {
		color: var(--amber);
		font-weight: 500;
	}

	.to {
		display: grid;
		grid-template-columns: minmax(0, 1fr) 420px;
		gap: 12px;
		margin: 0 16px 16px 0;
		min-height: 0;
	}
	.khung-ban-do {
		position: relative;
		min-height: 0;
		overflow: hidden;
		border-radius: 24px;
		background: #23402f;
	}
	.ban-do {
		position: absolute;
		inset: 0;
	}
	.ban-do.dang-ve :global(canvas) {
		cursor: crosshair;
	}
	.goi-y-ve {
		position: absolute;
		left: 16px;
		top: 16px;
		padding: 10px 16px;
		border-radius: 12px;
		background: #fff;
		color: var(--muc);
	}
	:global(.nhan-lo) {
		display: grid;
		padding: 4px 10px;
		border-radius: 10px;
		background: rgb(26 26 26 / 0.72);
		color: #fff;
		font: 500 0.8125rem/1.3 var(--sans);
		text-align: center;
		white-space: nowrap;
		pointer-events: none;
	}
	:global(.nhan-lo small) {
		color: #d6d5cf;
		font-size: 0.75rem;
	}
	:global(.nhan-lo.chon) {
		background: var(--teal);
	}
	.bang {
		display: flex;
		flex-direction: column;
		gap: 16px;
		padding: 28px;
		overflow-y: auto;
		border-radius: 24px;
		background: #fff;
	}
	.bang h1 {
		font-size: 1.875rem;
	}
	.vet {
		display: flex;
		gap: 6px;
		color: var(--mo);
	}
	.so-lieu {
		display: grid;
		margin: 0;
	}
	.so-lieu div {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		gap: 16px;
		padding: 14px 0;
		border-bottom: 1px solid var(--ke);
	}
	.so-lieu dt {
		color: var(--mo);
	}
	.so-lieu dd {
		margin: 0;
		color: var(--muc);
		font: 600 1.25rem var(--serif);
	}
	.goi-y {
		color: var(--mo);
	}
	form {
		display: grid;
		gap: 14px;
	}
	.hang {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
	}
	.canh-bao {
		color: var(--xau);
		font-size: 0.875rem;
	}
	.thanh-cong {
		color: var(--tot);
		font-weight: 600;
	}
	@media (max-width: 1100px) {
		.to {
			grid-template-columns: minmax(0, 1fr) 360px;
		}
	}
	@media (max-width: 900px) {
		.ung-dung {
			display: block;
			height: auto;
			padding-bottom: 12px;
		}
		.thanh-tren {
			grid-template-columns: auto 1fr;
			height: 64px;
		}
		.ten {
			padding-left: 16px;
		}
		.tim,
		.nguoi {
			display: none;
		}
		.tai-khoan {
			justify-self: end;
		}
		.ben {
			padding: 4px 12px 12px;
		}
		.vi-nho {
			margin-top: 12px;
		}
		.to {
			display: grid;
			grid-template-columns: 1fr;
			margin: 0 12px;
		}
		.khung-ban-do {
			height: 55svh;
		}
		.bang {
			padding: 22px;
		}
	}
</style>
