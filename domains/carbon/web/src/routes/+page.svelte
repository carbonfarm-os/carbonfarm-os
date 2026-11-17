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
	let daTai = $state(false);
	let timLo = $state('');
	let oTim = $state<HTMLInputElement>();
	let tabBang = $state<'vi' | 'xa-vien' | 'bao-cao'>('vi');
	let tqSoCai = $state<{
		so_ket_qua_mrv: number;
		co2e_da_ghi_so_tan: number;
		tin_chi_da_cap: number;
		tin_chi_da_ban: number;
		seri_moi_nhat: string | null;
	} | null>(null);
	/** Cmd+K (macOS) hoặc Ctrl+K: đưa con trỏ vào ô tìm lô. */
	const laMac = typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform);
	function phimTat(e: KeyboardEvent) {
		if ((laMac ? e.metaKey : e.ctrlKey) && e.key.toLowerCase() === 'k' && oTim) {
			e.preventDefault();
			oTim.focus();
			oTim.select();
		}
	}
	const loLoc = $derived(lo.filter((l) => l.ten.toLocaleLowerCase('vi').includes(timLo.trim().toLocaleLowerCase('vi'))));
	const tongHa = $derived(lo.reduce((t, l) => t + Number(l.dienTichHa), 0));
	const tongVi = $derived(vi.reduce((t, k) => t + k.soLuong, 0));
	const thongKeXaVien = $derived(
		xaVien.map((x) => {
			const dsLo = lo.filter((l) => l.carbonXaVienByXaVienId?.hoTen === x.hoTen);
			const ha = dsLo.reduce((t, l) => t + Number(l.dienTichHa), 0);
			const tyLe = tongHa > 0 ? ha / tongHa : 0;
			return { ...x, dsLo, ha, tyLe, tinChiPhanBo: Math.round(tyLe * tongVi) };
		})
	);

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
			laCanBo = d.allCarbonCanBoHtxes.totalCount > 0 || (nd?.vai.includes('quan_tri') ?? false);
			if (!form.xaVienId && xaVien.length) form.xaVienId = xaVien[0].rowId;
			if (loChon) {
				const capNhat = lo.find((x) => x.rowId === loChon?.rowId) ?? null;
				loChon = capNhat;
			}
			loiTai = '';
			daTai = true;
			veLai();
			fetch('/kiem-chung/api/tong-quan')
				.then((r) => (r.ok ? r.json() : null))
				.then((j) => {
					if (j && typeof j.so_ket_qua_mrv === 'number') tqSoCai = j;
				})
				.catch(() => {});
		} catch (e) {
			loiTai = (e as Error).message;
		}
	}

	function chonLo(l: Lo) {
		dangVe = false;
		dinh = [];
		loChon = l;
		xemLop(null);
		veLai();
		const b = new LngLatBounds();
		for (const d of l.ranhGioi.coordinates[0]) b.extend(d);
		banDo?.fitBounds(b, { padding: 80, maxZoom: 15 });
		if (matchMedia('(max-width: 900px)').matches) khungBanDo?.scrollIntoView({ behavior: 'smooth', block: 'start' });
	}

	function boChon() {
		dangVe = false;
		dinh = [];
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
		taiDuLieu();
		banDo = new BanDo({
			container: khungBanDo,
			style: kieuBanDo(),
			bounds: NEN.toaDo[0].concat(NEN.toaDo[2]) as [number, number, number, number],
			attributionControl: { compact: true, customAttribution: NEN.ghiNguon },
			dragRotate: false,
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
			b.addSource('nhap', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });
			b.addLayer({
				id: 'nhap-nen',
				type: 'fill',
				source: 'nhap',
				filter: ['==', '$type', 'Polygon'],
				paint: { 'fill-color': '#ecba82', 'fill-opacity': 0.24 }
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
				paint: { 'circle-radius': 5, 'circle-color': '#ffffff', 'circle-stroke-color': '#0b5d4c', 'circle-stroke-width': 2.5 }
			});
			veLai();
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
	// Tiêu đề tab: trang chủ khi chưa đăng nhập; bàn làm việc đổi theo việc đang làm (vẽ lô mới, lô đang chọn)
	const tieuDe = $derived(
		!nd ? 'Trang chủ' : dangVe ? 'Đăng ký lô mới' : loChon ? `${loChon.ten} · Bàn làm việc` : 'Bàn làm việc'
	);
</script>

<svelte:head><title>{tieuDe} · CarbonFarm OS</title></svelte:head>

<svelte:window onkeydown={nd ? phimTat : undefined} />

{#if !nd}
	<TrangGioiThieu />
{:else}
	<div class="ung-dung">
		<header class="thanh-tren">
			<div class="thuong-hieu">
				<a class="ten" href="/">
					<img class="logo-anh" src="/nen/logo-transparent.png" alt="Logo CarbonFarm OS" width="34" height="34" />
					<span>CarbonFarm OS</span>
				</a>
				<span class="vach" aria-hidden="true"></span>
				{#if tenHtx}<span class="chip-htx">🌿 {tenHtx}</span>{/if}
			</div>

			<label class="tim">
				<span class="an">Tìm lô</span>
				<svg viewBox="0 0 20 20" aria-hidden="true"><circle cx="8.5" cy="8.5" r="5.5" /><path d="m13 13 4 4" /></svg>
				<input type="search" bind:value={timLo} placeholder="Tìm lô rừng theo tên (VD: Lô Đất Mũi 1)…" autocomplete="off" bind:this={oTim} aria-keyshortcuts={laMac ? 'Meta+K' : 'Control+K'} />
				<kbd class="phim-tat">{laMac ? '⌘K' : 'Ctrl K'}</kbd>
			</label>

			<div class="tai-khoan">
				<a class="lien-ket-kiem" href="/kiem-chung">Kiểm chứng</a>
				<div class="ho-so" title="{nd.ten} ({laCanBo ? 'Cán bộ HTX' : 'Xã viên'})">
					<div class="nguoi-khung">
						<span class="nguoi">{nd.ten.trim().charAt(0).toLocaleUpperCase('vi')}</span>
					</div>
					<div class="ho-so-chu">
						<strong>{nd.ten}</strong>
						<small>{laCanBo ? 'Cán bộ HTX' : 'Xã viên'}</small>
					</div>
				</div>
				<button class="chu" onclick={dangXuat}>Đăng xuất</button>
			</div>
		</header>

		<nav class="ben" aria-label="Lô đất của hợp tác xã">
			<div class="ben-dau">
				<div>
					<p class="nhom">Danh mục lô rừng</p>
					<p class="htx">{lo.length} lô đang hoạt động</p>
				</div>
				{#if laCanBo && xaVien.length && !dangVe}
					<button class="nut nhat nho" onclick={batDauVe}>+ Lô mới</button>
				{/if}
			</div>

			<ul class="ds-lo">
				{#each loLoc as l (l.rowId)}
					<li>
						<button class="the-lo" class:chon={l.rowId === loChon?.rowId} onclick={() => chonLo(l)}>
							<div class="the-lo-tren">
								<span class="ten-lo">
									<svg class="icon-lo" viewBox="0 0 16 16" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M8 2 2 5v6l6 3 6-3V5L8 2z"/></svg>
									{l.ten}
								</span>
								<span class="so">{Number(l.dienTichHa).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ha</span>
							</div>
							<div class="the-lo-duoi">
								<span>{l.carbonXaVienByXaVienId?.hoTen ?? 'Xã viên HTX'}</span>
								{#if l.namTrong}
									<span>· Trồng {l.namTrong}</span>
								{/if}
							</div>
						</button>
					</li>
				{:else}
					<li class="trong">{!daTai && !loiTai ? 'Đang tải danh sách lô…' : timLo ? 'Không có lô nào khớp từ khoá' : 'Chưa có lô nào bạn được xem'}</li>
				{/each}
			</ul>

			{#if laCanBo && xaVien.length && !dangVe}
				<button class="nut nhat nho them" onclick={batDauVe}>+ Đăng ký lô rừng mới trên bản đồ</button>
			{/if}

			<button class="vi-nho" class:chon={!loChon && !dangVe} onclick={boChon}>
				<div class="vi-nho-tren">
					<span class="nhom">
						<svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="12" height="10" rx="2"/><circle cx="10" cy="8" r="1.5"/></svg>
						Ví tín chỉ hợp tác xã
					</span>
					<span class="nhan-vi">1 t CO₂e / tín chỉ</span>
				</div>
				<div class="vi-nho-so">
					<span class="so-lon">{tongVi}</span>
					<span class="don-vi">tín chỉ khả dụng</span>
				</div>
				<span class="xem">{laCanBo ? 'Quản lý ví, xã viên & báo cáo →' : 'Tra cứu ví & phân bổ xã viên →'}</span>
			</button>
		</nav>

		<main class="to">
			<div class="khung-ban-do">
				<div class="ban-do" class:dang-ve={dangVe} bind:this={khungBanDo} aria-label="Bản đồ lô đất, ảnh Sentinel-2"></div>
				<div class="thanh-ban-do">
					<span class="cham-xanh" aria-hidden="true"></span>
					<span>Sentinel-2 L2A · 14/04/2026 · Mũi Cà Mau (10 m)</span>
					{#if lopNdvi}
						<span class="chu-thich-ndvi">
							<b>Lớp NDVI đang bật:</b>
							<i class="thang-ndvi" aria-hidden="true"></i>
							<span>0,0 → 1,0</span>
						</span>
					{/if}
				</div>
				{#if dangVe}
					<div class="goi-y-ve">
						<div>
							<strong>Chế độ vẽ ranh giới lô mới</strong>
							<p>Bấm lên bản đồ để chấm từng góc lô (tối thiểu 3 góc). Hệ thống tự kiểm tra chồng lấn và độ lệch diện tích.</p>
						</div>
						<div class="goi-y-so">
							<span><b>{dinh.length}</b> góc</span>
							<span><b>{dinh.length >= 3 ? `${dienTichVe.toFixed(2)} ha` : '0,00 ha'}</b></span>
							{#if dinh.length}
								<button type="button" class="chu" onclick={() => ((dinh = dinh.slice(0, -1)), veLai())}>Bỏ góc vừa đặt</button>
							{/if}
						</div>
					</div>
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
						<button class="chu" onclick={huyVe}>← Quay lại tổng quan</button>
					</div>
					<div class="dau-bang">
						<h1>Đăng ký lô mới</h1>
						<p class="goi-y">Chấm ít nhất 3 góc trên bản đồ vệ tinh bên trái rồi điền thông tin giấy tờ để đối chiếu.</p>
					</div>
					<dl class="o-kpi">
						<div>
							<dt>Số góc đã đặt</dt>
							<dd>{dinh.length}</dd>
						</div>
						<div>
							<dt>Diện tích vẽ trên ảnh</dt>
							<dd>{dinh.length >= 3 ? `${dienTichVe.toFixed(2)} ha` : '–'}</dd>
						</div>
						<div>
							<dt>Độ lệch giấy tờ</dt>
							<dd class:xau={lechKhaiBao !== null && lechKhaiBao > 0.1}>
								{lechKhaiBao !== null ? `${(lechKhaiBao * 100).toFixed(1)} %` : '≤ 10 %'}
							</dd>
						</div>
					</dl>
					{#if dinh.length}
						<button type="button" class="chu" onclick={() => ((dinh = dinh.slice(0, -1)), veLai())}>Bỏ góc vừa đặt</button>
					{/if}
					<form class="form-the" onsubmit={dangKy}>
						<label class="o-nhap">
							Xã viên đứng tên lô
							<select bind:value={form.xaVienId} required>
								{#each xaVien as x (x.rowId)}<option value={x.rowId}>{x.maXaVien} · {x.hoTen}</option>{/each}
							</select>
						</label>
						<label class="o-nhap">Tên lô rừng <input bind:value={form.ten} required minlength="2" maxlength="120" placeholder="Ví dụ: Lô Đất Mũi 3" /></label>
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
							<p class="canh-bao">Lệch {(lechKhaiBao * 100).toFixed(0)} % so với diện tích vẽ; hệ thống chỉ nhận lệch tối đa 10 % (mã lỗi UC004).</p>
						{/if}
						{#if loi}
							<div role="alert" class="loi"><b>{loi.thongBao}</b>{#if loi.goiY}<br />{loi.goiY}{/if}</div>
						{/if}
						<div class="hang-nut">
							<button class="nut rong" type="submit" disabled={dinh.length < 3 || dangGui}>{dangGui ? 'Đang gửi…' : 'Đăng ký lô'}</button>
							<button class="nut nhat" type="button" onclick={huyVe}>Huỷ</button>
						</div>
					</form>
				{:else}
					<div class="dau-bang">
						<div class="dau-bang-tren">
							<h1>{tenHtx || 'Hợp tác xã'}</h1>
							<span class="nhan tot">Đang hoạt động</span>
						</div>
						<p class="goi-y">Chọn một lô trên bản đồ hoặc ở cột trái để xem kết quả đo sinh khối vệ tinh và duyệt ghi sổ cái.</p>
					</div>

					<dl class="o-kpi">
						<div class="kpi-the">
							<div class="kpi-dau">
								<dt>Lô hoạt động</dt>
								<svg class="kpi-icon" viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 2 2 5v6l6 3 6-3V5L8 2z"/></svg>
							</div>
							<dd>{lo.length}</dd>
						</div>
						<div class="kpi-the">
							<div class="kpi-dau">
								<dt>Diện tích ranh giới</dt>
								<svg class="kpi-icon" viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><circle cx="8" cy="8" r="6"/><path d="M8 2v12M2 8h12"/></svg>
							</div>
							<dd>{tongHa.toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ha</dd>
						</div>
						<div class="kpi-the">
							<div class="kpi-dau">
								<dt>Tín chỉ khả dụng</dt>
								<svg class="kpi-icon" viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="12" height="10" rx="2"/><circle cx="10" cy="8" r="1.5"/></svg>
							</div>
							<dd class="dd-tin-chi">{tongVi}</dd>
						</div>
					</dl>

					<div class="thanh-tab" role="tablist" aria-label="Phân khu bàn làm việc">
						<button
							type="button"
							role="tab"
							aria-selected={tabBang === 'vi'}
							class="nut-tab"
							class:chon={tabBang === 'vi'}
							onclick={() => (tabBang = 'vi')}
						>
							Ví & Giao dịch
						</button>
						<button
							type="button"
							role="tab"
							aria-selected={tabBang === 'xa-vien'}
							class="nut-tab"
							class:chon={tabBang === 'xa-vien'}
							onclick={() => (tabBang = 'xa-vien')}
						>
							Xã viên & Phân bổ ({xaVien.length})
						</button>
						<button
							type="button"
							role="tab"
							aria-selected={tabBang === 'bao-cao'}
							class="nut-tab"
							class:chon={tabBang === 'bao-cao'}
							onclick={() => (tabBang = 'bao-cao')}
						>
							Báo cáo & Sổ cái
						</button>
					</div>

					{#if !laCanBo}
						<p class="ghi-chu-vai">
							Đang xem với vai trò <b>Xã viên HTX</b> (quyền đọc theo RLS). Các thao tác đăng ký lô mới, yêu cầu đo MRV và duyệt lệnh bán dành cho Cán bộ HTX.
						</p>
					{/if}

					{#if thanhCong}<p class="thanh-cong">{thanhCong}</p>{/if}

					{#if tabBang === 'vi'}
						{#if token}
							<ViTinChi {token} {laCanBo} {vi} onThayDoi={taiDuLieu} />
						{/if}
					{:else if tabBang === 'xa-vien'}
						<section class="khung-tab" aria-label="Danh sách xã viên và phân bổ tín chỉ">
							<div class="dau-tab-con">
								<h2>Hộ xã viên & tỷ lệ phân bổ</h2>
								<span class="nhan">Theo tỷ trọng diện tích rừng</span>
							</div>
							<p class="phu-tab">
								Tín chỉ khả dụng trong ví HTX ({tongVi} tín chỉ) được hạch toán minh bạch theo tỷ lệ diện tích rừng ngập mặn đang canh tác của từng xã viên.
							</p>
							<ul class="ds-xa-vien">
								{#each thongKeXaVien as xv (xv.rowId)}
									<li class="the-xa-vien">
										<div class="xv-dau">
											<div>
												<strong>{xv.hoTen}</strong>
												<span class="ma-xv">{xv.maXaVien}</span>
											</div>
											<span class="nhan tot">≈ {xv.tinChiPhanBo} tín chỉ</span>
										</div>
										<div class="xv-so">
											<span><b>{xv.dsLo.length}</b> lô rừng</span>
											<span>·</span>
											<span><b>{xv.ha.toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ha</b> ({(xv.tyLe * 100).toLocaleString('vi-VN', { maximumFractionDigits: 1 })}%)</span>
										</div>
										{#if xv.dsLo.length}
											<div class="xv-lo">
												{#each xv.dsLo as l (l.rowId)}
													<button type="button" class="chip-lo-xv" onclick={() => chonLo(l)}>
														{l.ten} ({Number(l.dienTichHa).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ha) →
													</button>
												{/each}
											</div>
										{/if}
									</li>
								{/each}
							</ul>
						</section>
					{:else}
						<section class="khung-tab" aria-label="Báo cáo tổng hợp sổ cái và tuân thủ">
							<div class="dau-tab-con">
								<h2>Báo cáo MRV & Sổ cái Dolt</h2>
								<span class="nhan tot">TT 11/2026/TT-BNNMT</span>
							</div>
							{#if tqSoCai}
								{@const daCap = tqSoCai.tin_chi_da_cap || 0}
								{@const daBan = tqSoCai.tin_chi_da_ban || 0}
								{@const tyLeBan = daCap > 0 ? Math.min(100, Math.round((daBan / daCap) * 100)) : 0}
								<div class="luoi-bao-cao">
									<div class="o-bc">
										<span>Kỳ MRV đã ghi sổ</span>
										<strong>{tqSoCai.so_ket_qua_mrv.toLocaleString('vi-VN')}</strong>
									</div>
									<div class="o-bc">
										<span>Tổng hấp thụ CO₂e</span>
										<strong>{Number(tqSoCai.co2e_da_ghi_so_tan).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} t</strong>
									</div>
									<div class="o-bc">
										<span>Tín chỉ đã cấp sê-ri</span>
										<strong>{daCap.toLocaleString('vi-VN')}</strong>
									</div>
									<div class="o-bc">
										<span>Tín chỉ đã chuyển nhượng</span>
										<strong>{daBan.toLocaleString('vi-VN')} ({tyLeBan}%)</strong>
									</div>
								</div>
								<div class="thanh-ty-le-khung">
									<div class="thanh-ty-le-nhan">
										<span>Đang nắm giữ trong ví: <b>{tongVi}</b></span>
										<span>Đã bán chuyển nhượng: <b>{daBan}</b></span>
									</div>
									<div class="thanh-ty-le" role="img" aria-label="Tỷ lệ tín chỉ đã bán trên tổng phát hành">
										<div class="phan-ban" style="width: {tyLeBan}%"></div>
									</div>
								</div>
							{/if}
							<dl class="bang-tuan-thu">
								<div>
									<dt>Phương pháp luận áp dụng</dt>
									<dd>IPCC 2013 Wetlands Supplement · Chương 4 Tier 1 (cận dưới KTC 95%: 21,74 t CO₂e/ha/năm)</dd>
								</div>
								<div>
									<dt>Nguồn ảnh viễn thám</dt>
									<dd>ESA Copernicus Sentinel-2 L2A (10 m, lọc mây SCL + ngưỡng tán NDVI ≥ 0,40)</dd>
								</div>
								<div>
									<dt>Cơ chế kiểm soát nội bộ</dt>
									<dd>Poka-yoke hình học PostGIS (UC001–UC008) + Duyệt chéo 2 cán bộ HTX (UC032)</dd>
								</div>
							</dl>
							<a class="nut nhat rong" href="/kiem-chung">Mở Cổng kiểm chứng sổ cái công khai →</a>
						</section>
					{/if}
				{/if}
			</section>
		</main>
	</div>
{/if}

<style>
	.ung-dung {
		display: grid;
		grid-template-columns: 288px minmax(0, 1fr);
		grid-template-rows: 68px minmax(0, 1fr);
		height: 100dvh;
		background: var(--giay);
		font-family: var(--sans);
		font-size: 0.9375rem;
	}

	/* Thanh trên */
	.thanh-tren {
		grid-column: 1 / -1;
		display: grid;
		grid-template-columns: auto minmax(180px, 320px) auto;
		justify-content: space-between;
		align-items: center;
		gap: 12px;
		padding: 0 16px;
		border-bottom: 1px solid var(--ke);
		background: rgb(255 255 255 / 0.86);
		backdrop-filter: blur(10px);
	}
	.thuong-hieu {
		display: flex;
		align-items: center;
		gap: 10px;
		min-width: 0;
		flex-shrink: 0;
	}
	.ten {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		color: var(--muc);
		font: 700 1.0625rem var(--sans);
		letter-spacing: -0.02em;
		text-decoration: none;
		white-space: nowrap;
	}
	.logo-anh {
		display: block;
		width: 32px;
		height: 32px;
		object-fit: contain;
		filter: drop-shadow(0 2px 4px rgb(11 93 76 / 0.15));
	}
	.vach {
		width: 1px;
		height: 18px;
		background: var(--ke);
	}
	.chip-htx {
		overflow: hidden;
		max-width: 150px;
		padding: 3px 8px;
		border: 1px solid var(--ke);
		border-radius: 999px;
		background: var(--giay);
		color: var(--mo);
		font-size: 0.75rem;
		font-weight: 500;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.tim {
		position: relative;
		width: 100%;
	}
	.tim svg {
		position: absolute;
		left: 14px;
		top: 50%;
		width: 16px;
		height: 16px;
		transform: translateY(-50%);
		fill: none;
		stroke: var(--mo);
		stroke-width: 1.8;
		stroke-linecap: round;
	}
	.tim input {
		width: 100%;
		height: 40px;
		padding: 0 48px 0 38px;
		border: 1px solid var(--ke);
		border-radius: 999px;
		background: var(--giay);
		color: var(--muc);
		font: 400 0.875rem var(--sans);
		transition: border-color 0.15s var(--de), background-color 0.15s var(--de);
	}
	.tim input:focus {
		outline: none;
		border-color: var(--teal);
		background: #fff;
	}
	.phim-tat {
		position: absolute;
		right: 12px;
		top: 50%;
		transform: translateY(-50%);
		padding: 2px 6px;
		border: 1px solid var(--ke);
		border-radius: 6px;
		background: #ffffff;
		color: var(--mo);
		font: 600 0.6875rem var(--mono);
		pointer-events: none;
	}

	.tai-khoan {
		display: flex;
		align-items: center;
		gap: 14px;
	}
	.lien-ket-kiem {
		color: var(--teal);
		font-size: 0.875rem;
		font-weight: 600;
		text-decoration: none;
		white-space: nowrap;
	}
	.lien-ket-kiem:hover {
		text-decoration: underline;
	}
	.ho-so {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 4px 10px 4px 4px;
		border: 1px solid var(--ke);
		border-radius: 999px;
		background: #fff;
	}
	.nguoi-khung {
		position: relative;
	}
	.nguoi {
		display: grid;
		place-items: center;
		width: 30px;
		height: 30px;
		border-radius: 50%;
		background: linear-gradient(135deg, var(--teal) 0%, #059669 100%);
		color: #fff;
		font: 600 0.8125rem var(--sans);
	}
	.ho-so-chu {
		display: grid;
		line-height: 1.15;
	}
	.ho-so-chu strong {
		color: var(--muc);
		font-size: 0.8125rem;
		font-weight: 600;
	}
	.ho-so-chu small {
		color: var(--mo);
		font-size: 0.6875rem;
	}
	.chu {
		min-height: 32px;
		padding: 0;
		border: 0;
		background: none;
		color: var(--teal);
		font: 600 0.875rem var(--sans);
		text-decoration: underline;
		text-underline-offset: 0.22em;
		cursor: pointer;
		white-space: nowrap;
	}
	.chu:hover {
		color: var(--teal-dam);
	}

	/* Cột bên trái */
	.ben {
		display: flex;
		flex-direction: column;
		gap: 10px;
		padding: 16px;
		overflow-y: auto;
	}
	.ben-dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 8px;
		padding: 0 4px;
	}
	.nhom {
		margin: 0;
		color: var(--mo);
		font-size: 0.75rem;
		font-weight: 600;
		letter-spacing: 0.04em;
		text-transform: uppercase;
	}
	.htx {
		margin: 2px 0 0;
		color: var(--muc);
		font: 700 1.0625rem/1.25 var(--sans);
	}
	.ds-lo {
		display: grid;
		gap: 8px;
		margin: 0;
		padding: 0;
		list-style: none;
	}
	.the-lo {
		display: grid;
		gap: 4px;
		width: 100%;
		padding: 12px 14px;
		border: 1px solid var(--ke);
		border-radius: 14px;
		background: #ffffff;
		color: var(--muc);
		font: inherit;
		text-align: left;
		cursor: pointer;
		transition: border-color 0.15s var(--de), background-color 0.15s var(--de), transform 0.15s var(--de), box-shadow 0.15s var(--de);
	}
	.the-lo:hover {
		border-color: var(--teal-vien);
		background: var(--nen-mem);
		transform: translateY(-1px);
		box-shadow: 0 3px 8px -2px rgba(10, 31, 25, 0.05);
	}
	.the-lo.chon {
		border-color: var(--teal);
		background: var(--teal-nhat);
		color: var(--teal-dam);
		box-shadow: 0 2px 8px -2px rgba(11, 99, 81, 0.16);
	}
	.the-lo-tren {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		gap: 8px;
	}
	.ten-lo {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		font-weight: 600;
	}
	.icon-lo {
		color: var(--teal);
		flex-shrink: 0;
	}
	.so {
		color: var(--teal);
		font-size: 0.875rem;
		font-weight: 600;
		font-variant-numeric: tabular-nums;
	}
	.the-lo-duoi {
		display: flex;
		gap: 6px;
		color: var(--mo);
		font-size: 0.75rem;
	}
	.trong {
		padding: 14px 10px;
		border: 1px dashed var(--ke);
		border-radius: 14px;
		color: var(--mo);
		font-size: 0.875rem;
		text-align: center;
	}
	.them {
		width: 100%;
	}

	/* Thẻ Ví tín chỉ kiểu Fintech cao cấp */
	.vi-nho {
		display: grid;
		gap: 8px;
		margin-top: auto;
		padding: 18px;
		border: 1px solid rgba(255, 255, 255, 0.15);
		border-radius: 18px;
		background: linear-gradient(135deg, #0b6351 0%, #07473a 100%);
		color: #ffffff;
		font: inherit;
		text-align: left;
		cursor: pointer;
		box-shadow: 0 6px 18px -4px rgba(11, 99, 81, 0.35);
		transition: transform 0.16s var(--de), box-shadow 0.16s var(--de);
	}
	.vi-nho:hover,
	.vi-nho.chon {
		transform: translateY(-2px);
		box-shadow: 0 10px 24px -4px rgba(11, 99, 81, 0.45);
	}
	.vi-nho-tren {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 8px;
	}
	.vi-nho .nhom {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		color: #d1fae5;
	}
	.nhan-vi {
		padding: 2px 7px;
		border-radius: 999px;
		background: rgba(255, 255, 255, 0.18);
		color: #ffffff;
		font-size: 0.6875rem;
		font-weight: 600;
		white-space: nowrap;
	}
	.vi-nho-so {
		display: flex;
		align-items: baseline;
		gap: 8px;
	}
	.so-lon {
		color: #ffffff;
		font: 700 2.25rem/1 var(--sans);
		letter-spacing: -0.03em;
		font-variant-numeric: tabular-nums;
	}
	.don-vi {
		color: #a7f3d0;
		font-size: 0.8125rem;
		font-weight: 500;
	}
	.xem {
		color: #d1fae5;
		font-size: 0.8125rem;
		font-weight: 600;
	}

	/* Khu vực chính: Bản đồ + Bảng chi tiết */
	.to {
		display: grid;
		grid-template-columns: minmax(0, 1fr) 440px;
		gap: 14px;
		padding: 14px 16px 16px 0;
		min-height: 0;
	}
	.khung-ban-do {
		position: relative;
		min-height: 0;
		overflow: hidden;
		border: 1px solid var(--ke);
		border-radius: 22px;
		background: #1b382c;
		box-shadow: var(--bong);
	}
	.ban-do {
		position: absolute;
		inset: 0;
	}
	.ban-do.dang-ve :global(canvas) {
		cursor: crosshair;
	}
	.thanh-ban-do {
		position: absolute;
		left: 14px;
		top: 14px;
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 10px;
		max-width: calc(100% - 72px);
		padding: 7px 13px;
		border: 1px solid rgb(255 255 255 / 0.22);
		border-radius: 999px;
		background: rgb(20 38 32 / 0.78);
		backdrop-filter: blur(8px);
		color: #f4f9f6;
		font-size: 0.75rem;
		font-weight: 500;
		pointer-events: none;
	}

	.chu-thich-ndvi {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		padding-left: 8px;
		border-left: 1px solid rgb(255 255 255 / 0.25);
	}
	.thang-ndvi {
		display: inline-block;
		width: 48px;
		height: 8px;
		border-radius: 999px;
		background: linear-gradient(90deg, #d73027 0%, #fee08b 50%, #1a9850 100%);
	}
	.goi-y-ve {
		position: absolute;
		left: 14px;
		right: 14px;
		bottom: 46px;
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 12px;
		padding: 12px 16px;
		border: 1px solid var(--ke);
		border-radius: 16px;
		background: rgb(255 255 255 / 0.95);
		backdrop-filter: blur(8px);
		color: var(--muc);
		box-shadow: var(--bong);
	}
	.goi-y-ve strong {
		display: block;
		font-size: 0.875rem;
	}
	.goi-y-ve p {
		margin-top: 2px;
		color: var(--mo);
		font-size: 0.8125rem;
	}
	.goi-y-so {
		display: flex;
		align-items: center;
		gap: 14px;
		font-size: 0.875rem;
		font-variant-numeric: tabular-nums;
	}
	:global(.nhan-lo) {
		display: grid;
		padding: 5px 11px;
		border: 1px solid rgb(255 255 255 / 0.28);
		border-radius: 10px;
		background: rgb(20 38 32 / 0.84);
		backdrop-filter: blur(4px);
		color: #fff;
		font: 600 0.8125rem/1.25 var(--sans);
		text-align: center;
		white-space: nowrap;
		pointer-events: none;
		box-shadow: 0 4px 12px rgb(0 0 0 / 0.22);
	}
	:global(.nhan-lo small) {
		color: #cbe6de;
		font-size: 0.75rem;
		font-weight: 500;
		font-variant-numeric: tabular-nums;
	}
	:global(.nhan-lo.chon) {
		border-color: #a7f3d0;
		background: var(--teal);
	}

	/* Bảng chi tiết bên phải */
	.bang {
		display: flex;
		flex-direction: column;
		gap: 12px;
		padding: 20px 22px;
		overflow-y: auto;
		border: 1px solid var(--ke);
		border-radius: 22px;
		background: #fff;
		box-shadow: var(--bong);
	}
	.dau-bang {
		display: grid;
		gap: 4px;
	}
	.dau-bang-tren {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		gap: 12px;
	}
	.bang h1 {
		font: 700 1.375rem/1.2 var(--sans);
		letter-spacing: -0.02em;
	}
	.vet {
		display: flex;
		gap: 6px;
		color: var(--mo);
	}
	.goi-y {
		color: var(--mo);
		font-size: 0.8125rem;
		line-height: 1.45;
	}

	.o-kpi {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 10px;
		margin: 0;
		padding: 12px 0;
		border-top: 1px solid var(--ke);
		border-bottom: 1px solid var(--ke);
	}
	.kpi-the {
		display: flex;
		flex-direction: column;
		gap: 6px;
		padding: 12px 14px;
		border: 1px solid var(--ke-mem);
		border-radius: 12px;
		background: var(--nen-mem);
		transition: border-color 0.15s var(--de);
	}
	.kpi-the:hover {
		border-color: var(--teal-vien);
	}
	.kpi-dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 6px;
	}
	.kpi-dau dt {
		color: var(--mo);
		font-size: 0.75rem;
		font-weight: 500;
	}
	.kpi-icon {
		color: var(--teal);
		opacity: 0.8;
	}
	.o-kpi dd {
		margin: 0;
		color: var(--muc);
		font: 700 1.25rem/1.2 var(--sans);
		font-variant-numeric: tabular-nums;
	}
	.dd-tin-chi {
		color: var(--teal) !important;
	}
	.o-kpi dd.xau {
		color: var(--xau);
	}

	.form-the {
		display: grid;
		gap: 14px;
		padding-top: 8px;
	}
	.hang {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
	}
	.hang-nut {
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 10px;
	}
	.canh-bao {
		padding: 10px 12px;
		border: 1px solid #f2d194;
		border-radius: 12px;
		background: var(--amber-nhat);
		color: var(--amber-chu);
		font-size: 0.8125rem;
		font-weight: 500;
	}
	.thanh-cong {
		padding: 12px 14px;
		border: 1px solid #b5dcce;
		border-radius: 12px;
		background: var(--teal-nhat);
		color: var(--tot);
		font-size: 0.875rem;
		font-weight: 600;
	}

	.thanh-tab {
		display: grid;
		grid-template-columns: repeat(3, minmax(0, 1fr));
		gap: 6px;
		padding: 4px;
		border: 1px solid var(--ke);
		border-radius: 14px;
		background: var(--giay);
	}
	.nut-tab {
		min-height: 36px;
		padding: 0 8px;
		border: 0;
		border-radius: 10px;
		background: transparent;
		color: var(--mo);
		font: 600 0.78rem var(--sans);
		cursor: pointer;
		transition: all 0.15s var(--de);
	}
	.nut-tab:hover {
		color: var(--muc);
	}
	.nut-tab.chon {
		background: #ffffff;
		color: var(--teal-dam);
		box-shadow: 0 1px 3px rgba(10, 31, 25, 0.08);
	}
	.ghi-chu-vai {
		padding: 10px 12px;
		border: 1px solid var(--teal-vien);
		border-radius: 12px;
		background: var(--teal-nhat);
		color: var(--teal-dam);
		font-size: 0.8125rem;
		line-height: 1.45;
	}
	.khung-tab {
		display: flex;
		flex-direction: column;
		gap: 12px;
		padding-top: 8px;
	}
	.dau-tab-con {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 8px;
	}
	.dau-tab-con h2 {
		font: 700 1.0625rem var(--sans);
	}
	.phu-tab {
		color: var(--mo);
		font-size: 0.8125rem;
		line-height: 1.45;
	}
	.ds-xa-vien {
		display: grid;
		gap: 10px;
		margin: 0;
		padding: 0;
		list-style: none;
	}
	.the-xa-vien {
		display: grid;
		gap: 8px;
		padding: 14px;
		border: 1px solid var(--ke);
		border-radius: 14px;
		background: #ffffff;
	}
	.xv-dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 8px;
	}
	.xv-dau strong {
		font-size: 0.9375rem;
	}
	.ma-xv {
		margin-left: 6px;
		padding: 2px 6px;
		border-radius: 6px;
		background: var(--giay);
		color: var(--mo);
		font: 600 0.72rem var(--mono);
	}
	.xv-so {
		display: flex;
		gap: 6px;
		color: var(--mo);
		font-size: 0.8125rem;
		font-variant-numeric: tabular-nums;
	}
	.xv-lo {
		display: flex;
		flex-wrap: wrap;
		gap: 6px;
	}
	.chip-lo-xv {
		padding: 4px 10px;
		border: 1px solid var(--teal-vien);
		border-radius: 999px;
		background: var(--teal-nhat);
		color: var(--teal-dam);
		font: 600 0.75rem var(--sans);
		cursor: pointer;
	}
	.luoi-bao-cao {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 10px;
	}
	.o-bc {
		display: grid;
		gap: 4px;
		padding: 12px 14px;
		border: 1px solid var(--ke);
		border-radius: 12px;
		background: var(--nen-mem);
	}
	.o-bc span {
		color: var(--mo);
		font-size: 0.75rem;
	}
	.o-bc strong {
		color: var(--muc);
		font: 700 1.125rem var(--sans);
		font-variant-numeric: tabular-nums;
	}
	.thanh-ty-le-khung {
		display: grid;
		gap: 6px;
		padding: 12px 14px;
		border: 1px solid var(--ke);
		border-radius: 12px;
		background: #ffffff;
	}
	.thanh-ty-le-nhan {
		display: flex;
		justify-content: space-between;
		font-size: 0.78rem;
		color: var(--mo);
	}
	.thanh-ty-le {
		height: 10px;
		overflow: hidden;
		border-radius: 999px;
		background: var(--teal-nhat);
	}
	.phan-ban {
		height: 100%;
		background: var(--teal);
	}
	.bang-tuan-thu {
		display: grid;
		gap: 10px;
		margin: 0;
		padding: 12px 14px;
		border: 1px solid var(--ke);
		border-radius: 14px;
		background: #ffffff;
	}
	.bang-tuan-thu div {
		display: grid;
		gap: 2px;
	}
	.bang-tuan-thu dt {
		color: var(--mo);
		font-size: 0.75rem;
	}
	.bang-tuan-thu dd {
		margin: 0;
		color: var(--muc);
		font-size: 0.8125rem;
		font-weight: 600;
		line-height: 1.4;
	}

	@media (max-width: 1200px) {
		.chip-htx,
		.vach {
			display: none;
		}
		.to {
			grid-template-columns: minmax(0, 1fr) 390px;
		}
	}
	@media (max-width: 960px) {
		.ung-dung {
			display: flex;
			flex-direction: column;
			height: auto;
			min-height: 100dvh;
			padding-bottom: 16px;
		}
		.thanh-tren {
			display: flex;
			justify-content: space-between;
			align-items: center;
			gap: 10px;
			padding: 10px 14px;
		}
		.tim,
		.ho-so {
			display: none;
		}
		.thuong-hieu {
			flex-shrink: 0;
		}
		.tai-khoan {
			gap: 12px;
		}
		.ben {
			padding: 12px 14px;
		}
		.vi-nho {
			margin-top: 8px;
		}
		.to {
			grid-template-columns: 1fr;
			padding: 0 14px;
		}
		.khung-ban-do {
			height: 52svh;
		}
		.bang {
			padding: 20px;
		}
	}
</style>
