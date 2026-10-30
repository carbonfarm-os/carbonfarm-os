<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!--
	Trang chủ công khai. Mảng mòng két đầu trang mang câu chính và một tấm ảnh vệ tinh thật của lô vừa đo, ranh lô vẽ từ
	sổ cái. Mọi số liệu đọc từ /kiem-chung/api (không số viết cứng); ô tra cứu sê-ri chạy ngay trên trang.
-->
<script lang="ts">
	import { onMount } from 'svelte';
	import { batDauDangNhap } from './dang-nhap.ts';

	type DaGiac = { type: 'Polygon'; coordinates: number[][][] };
	type TongQuan = {
		so_ket_qua_mrv: number;
		co2e_da_ghi_so_tan: number;
		tin_chi_da_cap: number;
		tin_chi_da_ban: number;
		seri_moi_nhat: string | null;
		lo_da_do: { id: string; ten: string; ranh_gioi: DaGiac }[];
		ket_qua_moi_nhat: {
			ten_lo: string | null;
			ranh_gioi: DaGiac | null;
			dien_tich_tan_ha: string | number | null;
			co2e_tan: string | number | null;
			ndvi_tb_tan: number | null;
			ngay_chup: string;
			may_toan_canh: number | null;
			commit: string;
		} | null;
	};
	type KetQuaTra = {
		toan_ven: boolean;
		chu_so_huu_theo_so_cai: { ten: string };
		su_kien: { loai: string; commit: string }[];
	};

	const REPO = 'https://github.com/carbonfarm-os/carbonfarm-os';
	const DAC_TA = `${REPO}/blob/main/methodology/v0.1-rung-ngap-man-ipcc-tier1.md`;
	// Ảnh /anh/the-lo-mui-ca-mau.webp phủ đúng khung này (EPSG:4326)
	const ANH = { tay: 104.735, dong: 104.8205, nam: 8.617, bac: 8.675, rong: 1280, cao: 868 };
	const BUOC = [
		{
			so: '01',
			ten: 'Vẽ lô trên ảnh vệ tinh',
			giai: 'Cán bộ hợp tác xã vẽ ranh giới lô. Hình sai, lô chồng lấn hay diện tích lệch giấy tờ quá 10 % bị chặn ngay.'
		},
		{
			so: '02',
			ten: 'Đo tán rừng bằng Sentinel-2',
			giai: 'Cảnh ít mây được cắt theo lô, tán rừng tính từ NDVI rồi quy ra CO₂e bằng hệ số IPCC cận dưới.'
		},
		{
			so: '03',
			ten: 'Duyệt, ghi sổ, cấp tín chỉ',
			giai: 'Chỉ kết quả được cán bộ duyệt mới lên sổ cái. Một tín chỉ là một tấn CO₂e, mang sê-ri theo Thông tư 11/2026.'
		}
	];
	const HE_SO = [
		['Hấp thụ sinh khối trên mặt đất', '9,4 t/ha/năm'],
		['Tỉ lệ carbon trong sinh khối', '0,47'],
		['Tỉ lệ rễ trên thân', '0,429'],
		['Quy đổi C → CO₂', '44/12'],
		['Kết quả cho một héc-ta tán kín', '21,74 t CO₂e/năm']
	];
	const LOAI: Record<string, string> = { ket_qua_mrv: 'đo', cap_tin_chi: 'cấp', ban_tin_chi: 'bán' };

	let tq = $state<TongQuan | null>(null);
	let traCuu = $state('');
	let ketQua = $state<KetQuaTra | null>(null);
	let loiTra = $state('');
	let dangTra = $state(false);

	const so = (v: number | string | null | undefined, n = 2) =>
		v === null || v === undefined ? '–' : Number(v).toLocaleString('vi-VN', { maximumFractionDigits: n });
	const ngay = (s: string | undefined) => (s ? s.split('-').reverse().join('/') : '–');

	const diem = (lon: number, lat: number): [number, number] => [
		((lon - ANH.tay) / (ANH.dong - ANH.tay)) * ANH.rong,
		((ANH.bac - lat) / (ANH.bac - ANH.nam)) * ANH.cao
	];
	const duong = (g: DaGiac) =>
		g.coordinates
			.map((vong) => 'M' + vong.map(([x, y]) => diem(x, y).map((v) => v.toFixed(1)).join(' ')).join('L') + 'Z')
			.join('');

	// Khung nhìn 4:3: bãi bồi phía trên, rừng đước và lô vừa đo phía dưới
	const khung = { x: 150, y: 160, w: 944, h: 708 };
	const tamLo = $derived.by(() => {
		const g = tq?.ket_qua_moi_nhat?.ranh_gioi;
		if (!g) return null;
		const d = g.coordinates[0].map(([x, y]) => diem(x, y));
		return { x: d.reduce((t, p) => t + p[0], 0) / d.length, y: Math.min(...d.map((p) => p[1])) };
	});

	async function tra(e: SubmitEvent) {
		e.preventDefault();
		const v = (traCuu || tq?.seri_moi_nhat || '').trim();
		if (!v) return;
		traCuu = v;
		dangTra = true;
		loiTra = '';
		ketQua = null;
		try {
			const r = await fetch(`/kiem-chung/api/${v.includes('-') ? 'seri' : 'commit'}/${encodeURIComponent(v)}`);
			const j = await r.json();
			if (!r.ok) throw new Error(j.loi ?? `Máy chủ trả mã ${r.status}`);
			ketQua = v.includes('-')
				? j
				: {
						toan_ven: j.ban_ghi.every((b: { sha256_khop: boolean }) => b.sha256_khop),
						chu_so_huu_theo_so_cai: { ten: '–' },
						su_kien: j.ban_ghi
					};
		} catch (err) {
			loiTra = (err as Error).message;
		} finally {
			dangTra = false;
		}
	}

	onMount(() => {
		fetch('/kiem-chung/api/tong-quan')
			.then((r) => (r.ok ? r.json() : null))
			.then((d) => (tq = d))
			.catch(() => {});
	});
</script>

<svelte:head>
	<title>CarbonFarm OS – rừng ngập mặn đo được, tín chỉ kiểm chứng được</title>
	<meta
		name="description"
		content="Phần mềm nguồn mở đo carbon rừng ngập mặn Cà Mau từ ảnh vệ tinh, cấp tín chỉ cho hợp tác xã và ghi lên sổ cái ai cũng kiểm chứng được."
	/>
</svelte:head>

<div class="trang">
	<section class="dau" aria-labelledby="tieu-de">
		<header class="thanh">
			<a class="ten" href="/">CarbonFarm OS</a>
			<nav aria-label="Trang chủ">
				<a href="#cach-lam">Cách làm</a>
				<a href="#phuong-phap">Phương pháp</a>
				<a href="/kiem-chung">Kiểm chứng</a>
			</nav>
			<button class="nut nho vien" onclick={batDauDangNhap}>Đăng nhập</button>
		</header>

		<div class="dau-giua">
			<div class="loi-chinh">
				<p class="vung">Rừng ngập mặn Mũi Cà Mau</p>
				<h1 id="tieu-de">Rừng đo được, tín chỉ kiểm chứng được.</h1>
				<p class="dan">
					CarbonFarm OS đo carbon rừng ngập mặn từ ảnh vệ tinh, cấp tín chỉ cho hợp tác xã và ghi lên sổ cái ai cũng
					tra được.
				</p>
				<div class="hanh-dong">
					<button class="nut" onclick={batDauDangNhap}>Đăng nhập cán bộ</button>
					<a class="nut vien" href="/kiem-chung">Kiểm chứng tín chỉ</a>
				</div>
			</div>

			<figure class="the-lo">
				<svg viewBox="{khung.x} {khung.y} {khung.w} {khung.h}" role="img" aria-label="Ảnh Sentinel-2 màu thật quanh {tq?.ket_qua_moi_nhat?.ten_lo ?? 'lô vừa đo'}, ranh lô lấy từ sổ cái">
					<image href="/anh/the-lo-mui-ca-mau.webp" width={ANH.rong} height={ANH.cao} preserveAspectRatio="none" />
					{#each tq?.lo_da_do ?? [] as lo (lo.id)}
						<path class="ranh" d={duong(lo.ranh_gioi)} vector-effect="non-scaling-stroke" />
					{/each}
					{#if tamLo && tq?.ket_qua_moi_nhat?.ten_lo}
						<g class="ghim" transform="translate({tamLo.x} {tamLo.y - 18})">
							<rect x="-92" y="-52" width="184" height="40" rx="20" />
							<text y="-25" text-anchor="middle">{tq.ket_qua_moi_nhat.ten_lo}</text>
							<path d="M0 -12V0" />
						</g>
					{/if}
				</svg>
				<figcaption>
					<div class="tieu">
						<b>{tq?.ket_qua_moi_nhat?.ten_lo ?? 'Đang đọc sổ cái…'}</b>
						<span class="nhan tot">Đã ghi sổ</span>
					</div>
					<dl>
						<div><dt>Diện tích tán</dt><dd>{so(tq?.ket_qua_moi_nhat?.dien_tich_tan_ha)} ha</dd></div>
						<div><dt>NDVI tán</dt><dd>{so(tq?.ket_qua_moi_nhat?.ndvi_tb_tan)}</dd></div>
						<div><dt>CO₂e</dt><dd>{so(tq?.ket_qua_moi_nhat?.co2e_tan)} t</dd></div>
						<div><dt>Ảnh chụp</dt><dd>{ngay(tq?.ket_qua_moi_nhat?.ngay_chup)}</dd></div>
					</dl>
				</figcaption>
			</figure>
		</div>
	</section>

	<section id="cach-lam" class="khoi" aria-labelledby="cach-lam-td">
		<h2 id="cach-lam-td">Từ ảnh vệ tinh đến tín chỉ, ba bước</h2>
		<ol class="ba-the">
			{#each BUOC as b (b.so)}
				<li>
					<span class="so-buoc">{b.so}</span>
					<h3>{b.ten}</h3>
					<p>{b.giai}</p>
				</li>
			{/each}
		</ol>
	</section>

	<section class="khoi tra-khoi" aria-labelledby="tra-td">
		<div class="tra-loi">
			<h2 id="tra-td">Ai cũng tra được một tín chỉ</h2>
			<p>
				Nhập số sê-ri hoặc mã băm. Kết quả đọc thẳng từ sổ cái: tín chỉ thuộc về ai, đã qua những bước nào, bản ghi có
				còn nguyên vẹn không.
			</p>
		</div>
		<div class="tra-tam">
			<form class="tra" onsubmit={tra}>
				<label class="o-nhap">
					Số sê-ri hoặc mã băm
					<input bind:value={traCuu} placeholder={tq?.seri_moi_nhat ?? 'MCK-DM01-26-0000000001'} autocomplete="off" spellcheck="false" />
				</label>
				<button class="nut" type="submit" disabled={dangTra}>{dangTra ? 'Đang tra…' : 'Tra cứu'}</button>
			</form>
			<div class="ket-qua" aria-live="polite">
				{#if loiTra}
					<p class="loi">{loiTra}</p>
				{:else if ketQua}
					<p class="dong-kq">
						<span class="nhan" class:tot={ketQua.toan_ven} class:xau={!ketQua.toan_ven}>{ketQua.toan_ven ? 'Toàn vẹn' : 'Có bản ghi không khớp'}</span>
						{#if ketQua.chu_so_huu_theo_so_cai.ten !== '–'}<span>Thuộc <b>{ketQua.chu_so_huu_theo_so_cai.ten}</b></span>{/if}
					</p>
					<p>Đã qua: {ketQua.su_kien.map((s) => LOAI[s.loai] ?? s.loai).join(' → ')}. <a href="/kiem-chung?q={encodeURIComponent(traCuu)}">Xem từng bản ghi</a></p>
				{:else}
					<p class="goi-y">Để trống rồi bấm Tra cứu để thử với sê-ri mới nhất trên sổ.</p>
				{/if}
			</div>
		</div>
	</section>

	<section id="phuong-phap" class="khoi pp" aria-labelledby="pp-td">
		<div class="pp-chu">
			<h2 id="pp-td">Thận trọng trước, có nguồn sau mỗi con số</h2>
			<p>
				Phương pháp v0.1 lấy hệ số IPCC 2013 cho rừng ngập mặn và luôn chọn cận dưới. Ảnh vệ tinh chỉ đo diện tích tán;
				rừng đã chạm trần sinh khối thì không tính thêm.
			</p>
			<p>Mỗi kết quả lưu phiên bản phương pháp, mã SHA-256 của tệp tham số, cảnh ảnh nguồn và người duyệt.</p>
			<a class="lien-ket" href={DAC_TA} rel="external">Đọc đặc tả phương pháp</a>
		</div>
		<div class="pp-tam">
			<img src="/anh/re-duoc-ca-mau.webp" alt="Rễ chống của cây đước trong rừng ngập mặn Cà Mau" width="900" height="900" loading="lazy" />
			<dl>
				{#each HE_SO as [k, v] (k)}
					<div><dt>{k}</dt><dd>{v}</dd></div>
				{/each}
			</dl>
		</div>
	</section>

	<section class="dao" aria-labelledby="so-cai-td">
		<div class="dao-trong">
			<h2 id="so-cai-td">Sổ cái lúc này</h2>
			<p class="dao-dan">Đọc trực tiếp từ Dolt bằng tài khoản chỉ đọc. Không con số nào trên trang được viết tay.</p>
			<ul class="so-lieu">
				<li><span class="lon">{so(tq?.co2e_da_ghi_so_tan, 1)}</span><span>tấn CO₂e đã ghi sổ</span></li>
				<li><span class="lon">{so(tq?.tin_chi_da_cap, 0)}</span><span>tín chỉ đã cấp</span></li>
				<li><span class="lon">{so(tq?.tin_chi_da_ban, 0)}</span><span>tín chỉ đã bán</span></li>
				<li><span class="lon">{so(tq?.so_ket_qua_mrv, 0)}</span><span>kết quả MRV được duyệt</span></li>
			</ul>
			{#if tq?.ket_qua_moi_nhat}
				<p class="commit">Commit mới nhất <code>{tq.ket_qua_moi_nhat.commit}</code></p>
			{/if}
		</div>
	</section>

	<figure class="nghi">
		<img src="/anh/bai-boi-dat-mui.webp" alt="Bãi bồi Đất Mũi: hàng cọc tre giữ phù sa, cây đước non mọc giữa bùn" width="1920" height="1440" loading="lazy" />
		<figcaption>Bãi bồi Đất Mũi. Hàng cọc tre giữ phù sa để cây đước non kịp bám rễ.</figcaption>
	</figure>

	<footer class="cuoi">
		<div>
			<a class="ten" href="/">CarbonFarm OS</a>
			<p>Phần mềm nguồn mở cho hợp tác xã ven biển, giấy phép <a href={REPO} rel="external">GPL-3.0-or-later</a>.</p>
			<p>Bản demo dùng hợp tác xã, xã viên giả; Registry, người mua, ngân hàng là mô phỏng.</p>
		</div>
		<nav aria-label="Chân trang">
			<a href="/kiem-chung">Kiểm chứng</a>
			<a href={DAC_TA} rel="external">Phương pháp</a>
			<a href={REPO} rel="external">Mã nguồn</a>
		</nav>
		<p class="nguon">
			Ảnh: rễ đước, Nevillenguyen310, CC BY-SA 4.0 · bãi bồi Đất Mũi, Alphama, CC BY 4.0 (Wikimedia Commons) · ảnh vệ
			tinh chứa dữ liệu Copernicus Sentinel 2026 đã qua xử lý.
		</p>
	</footer>
</div>

<style>
	.trang {
		padding: 12px;
	}

	/* Đầu trang: mảng mòng két bo sâu ở đáy */
	.dau {
		padding: 0 var(--le) clamp(48px, 7vw, 96px);
		border-radius: 24px 24px 64px 64px;
		background: var(--teal);
		color: #e4efec;
	}
	.thanh {
		display: flex;
		align-items: center;
		gap: 24px;
		max-width: var(--rong);
		min-height: 80px;
		margin: 0 auto;
	}
	.ten {
		color: inherit;
		font: 600 1.375rem var(--serif);
		letter-spacing: -0.02em;
		text-decoration: none;
	}
	.thanh .ten {
		color: #fff;
	}
	.thanh nav {
		display: flex;
		gap: 28px;
		margin-left: auto;
	}
	.thanh nav a {
		color: #d3e4e0;
		font-size: 0.9375rem;
		text-decoration: none;
	}
	.thanh nav a:hover {
		color: #fff;
	}

	.dau-giua {
		display: grid;
		grid-template-columns: minmax(0, 1fr) minmax(0, 0.95fr);
		gap: clamp(32px, 5vw, 80px);
		align-items: center;
		max-width: var(--rong);
		margin: clamp(24px, 5vw, 64px) auto 0;
	}
	.vung {
		margin-bottom: 20px;
		color: var(--amber);
		font-size: 0.9375rem;
		font-weight: 500;
	}
	h1 {
		max-width: 13ch;
		color: #fff;
		font-size: clamp(2.5rem, 5.4vw, 4.5rem);
		line-height: 1.04;
	}
	.dan {
		max-width: 46ch;
		margin-top: 24px;
		font-size: 1.125rem;
		line-height: 1.6;
	}
	.hanh-dong {
		display: flex;
		flex-wrap: wrap;
		gap: 12px;
		margin-top: 36px;
	}

	.the-lo {
		margin: 0;
		padding: 12px;
		border-radius: 28px;
		background: var(--tam);
		color: var(--than);
	}
	.the-lo svg {
		display: block;
		width: 100%;
		height: auto;
		aspect-ratio: 4 / 3;
		border-radius: 18px;
		background: #23402f;
	}
	.ranh {
		fill: rgb(236 186 130 / 0.35);
		stroke: var(--amber);
		stroke-width: 3;
	}
	.ghim rect {
		fill: #fff;
	}
	.ghim text {
		fill: var(--muc);
		font: 600 21px var(--sans);
	}
	.ghim path {
		stroke: #fff;
		stroke-width: 3;
	}
	figcaption {
		padding: 16px 8px 4px;
	}
	.tieu {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 12px;
	}
	.tieu b {
		color: var(--muc);
		font: 600 1.25rem var(--serif);
	}
	.the-lo dl {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 12px;
		margin: 16px 0 0;
	}
	dl {
		margin: 0;
	}
	dt {
		color: var(--mo);
		font-size: 0.8125rem;
	}
	dd {
		margin: 2px 0 0;
		color: var(--muc);
		font-weight: 600;
	}

	/* Các khối trên nền giấy */
	.khoi {
		max-width: var(--rong);
		margin: clamp(64px, 9vw, 120px) auto 0;
		padding: 0 var(--le);
	}
	.khoi h2 {
		font-size: clamp(2rem, 3.6vw, 3rem);
	}
	.ba-the {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 20px;
		margin: 40px 0 0;
		padding: 0;
		list-style: none;
	}
	.ba-the li {
		padding: 32px;
		border-radius: 28px;
		background: var(--tam);
	}
	.so-buoc {
		display: inline-grid;
		place-items: center;
		width: 48px;
		height: 48px;
		border-radius: 14px;
		background: var(--teal-nhat);
		color: var(--teal);
		font: 600 1.125rem var(--serif);
	}
	.ba-the h3 {
		margin-top: 28px;
		font-size: 1.5rem;
	}
	.ba-the p {
		margin-top: 12px;
	}

	.tra-khoi {
		display: grid;
		grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
		gap: clamp(32px, 5vw, 72px);
		align-items: start;
	}
	.tra-loi p {
		max-width: 44ch;
		margin-top: 20px;
		font-size: 1.0625rem;
	}
	.tra-tam {
		padding: 32px;
		border-radius: 28px;
		background: var(--tam);
	}
	.tra {
		display: grid;
		grid-template-columns: minmax(0, 1fr) auto;
		gap: 12px;
		align-items: end;
	}
	.ket-qua {
		margin-top: 20px;
		padding-top: 20px;
		border-top: 1px solid var(--ke);
	}
	.ket-qua p + p {
		margin-top: 10px;
	}
	.dong-kq {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 12px;
	}
	.goi-y {
		color: var(--mo);
	}
	.ket-qua a {
		color: var(--teal);
		font-weight: 500;
	}

	.pp {
		display: grid;
		grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
		gap: clamp(32px, 5vw, 72px);
		align-items: center;
	}
	.pp-chu p {
		max-width: 48ch;
		margin-top: 20px;
		font-size: 1.0625rem;
	}
	.pp-chu .lien-ket {
		display: inline-block;
		margin-top: 24px;
	}
	.pp-tam {
		display: grid;
		grid-template-columns: 0.8fr 1fr;
		gap: 0;
		overflow: hidden;
		border-radius: 28px;
		background: var(--tam);
	}
	.pp-tam img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.pp-tam dl {
		padding: 16px 28px;
	}
	.pp-tam dl div {
		padding: 14px 0;
		border-bottom: 1px solid var(--ke);
	}
	.pp-tam dl div:last-child {
		border-bottom: 0;
	}
	.pp-tam dl div:last-child dd {
		color: var(--teal);
		font: 600 1.25rem var(--serif);
	}

	/* Đảo tối: số liệu sổ cái */
	.dao {
		margin-top: clamp(64px, 9vw, 120px);
		padding: clamp(48px, 7vw, 96px) var(--le);
		border-radius: 48px;
		background: var(--dao);
		color: #c9c8c2;
	}
	.dao-trong {
		max-width: var(--rong);
		margin: 0 auto;
	}
	.dao h2 {
		color: #fff;
		font-size: clamp(2rem, 3.6vw, 3rem);
	}
	.dao-dan {
		max-width: 52ch;
		margin-top: 16px;
	}
	.so-lieu {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 16px;
		margin: 40px 0 0;
		padding: 0;
		list-style: none;
	}
	.so-lieu li {
		display: grid;
		gap: 8px;
		padding: 28px;
		border-radius: 24px;
		background: var(--teal);
		color: #cfe2de;
	}
	.lon {
		color: #fff;
		font: 600 clamp(2.25rem, 4vw, 3.25rem) / 1 var(--serif);
		letter-spacing: -0.02em;
	}
	.commit {
		margin-top: 24px;
		font-size: 0.875rem;
	}
	.commit code {
		color: var(--amber);
	}

	.nghi {
		max-width: var(--rong);
		margin: clamp(64px, 9vw, 120px) auto 0;
		padding: 0 var(--le);
	}
	.nghi img {
		width: 100%;
		aspect-ratio: 21 / 9;
		object-fit: cover;
		border-radius: 32px;
	}
	.nghi figcaption {
		padding: 12px 8px 0;
		color: var(--mo);
		font-size: 0.875rem;
	}

	.cuoi {
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 24px 48px;
		max-width: var(--rong);
		margin: clamp(48px, 7vw, 96px) auto 0;
		padding: 40px var(--le) 32px;
		border-top: 1px solid #e0dedb;
		font-size: 0.9375rem;
	}
	.cuoi .ten {
		color: var(--muc);
	}
	.cuoi p {
		margin-top: 8px;
		max-width: 60ch;
	}
	.cuoi nav {
		display: flex;
		gap: 24px;
	}
	.cuoi nav a {
		color: var(--teal);
		font-weight: 500;
	}
	.nguon {
		grid-column: 1 / -1;
		color: var(--mo);
		font-size: 0.8125rem;
	}

	@media (max-width: 960px) {
		.dau-giua,
		.tra-khoi,
		.pp {
			grid-template-columns: 1fr;
		}
		.ba-the,
		.so-lieu {
			grid-template-columns: 1fr 1fr;
		}
		.ba-the li:last-child {
			grid-column: 1 / -1;
		}
	}
	@media (max-width: 640px) {
		.trang {
			padding: 8px;
		}
		.dau {
			border-radius: 20px 20px 40px 40px;
		}
		.thanh nav {
			display: none;
		}
		.thanh .nut {
			margin-left: auto;
		}
		.the-lo dl {
			grid-template-columns: 1fr 1fr;
		}
		.ba-the,
		.so-lieu {
			grid-template-columns: 1fr;
		}
		.ba-the li {
			padding: 24px;
		}
		.tra {
			grid-template-columns: 1fr;
		}
		.tra-tam {
			padding: 24px;
		}
		.pp-tam {
			grid-template-columns: 1fr;
		}
		.pp-tam img {
			aspect-ratio: 16 / 9;
		}
		.dao {
			border-radius: 32px;
		}
		.nghi img {
			aspect-ratio: 4 / 3;
		}
		.cuoi {
			grid-template-columns: 1fr;
		}
		.cuoi nav {
			flex-wrap: wrap;
		}
	}
</style>
