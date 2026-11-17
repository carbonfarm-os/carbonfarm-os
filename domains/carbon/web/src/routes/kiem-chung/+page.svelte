<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!--
	Trang kiểm chứng CÔNG KHAI (#38), không cần đăng nhập: nhập mã băm commit Dolt hoặc số sê-ri tín chỉ, xem bản ghi gốc
	trong sổ cái, SHA-256 tính lại có khớp không, và chuỗi sự kiện MRV → cấp → bán. Gọi /kiem-chung/api (chỉ đọc).
-->
<script lang="ts">
	import { onMount } from 'svelte';

	type BanGhi = {
		loai: string;
		ma_doi_tuong: string;
		commit: string;
		luc: string;
		sha256_so_cai: string;
		sha256_tinh_lai: string;
		sha256_khop: boolean;
		con_nguyen_ven: boolean;
		du_lieu: Record<string, unknown>;
	};
	type KetQua =
		| { kieu: 'commit'; commit: string; luc: string; thong_diep: string; ban_ghi: BanGhi[] }
		| { kieu: 'seri'; so_seri: string; chu_so_huu_theo_so_cai: { ten: string; ma_so_thue: string }; toan_ven: boolean; su_kien: BanGhi[] };

	const LOAI: Record<string, string> = {
		ket_qua_mrv: 'Đo từ vệ tinh, cán bộ đã duyệt',
		cap_tin_chi: 'Registry cấp tín chỉ',
		ban_tin_chi: 'Bán, chuyển quyền sở hữu'
	};
	const BUOC_NHAN: Record<string, string> = {
		ket_qua_mrv: 'Bước 01 · Ghi nhận sinh khối MRV',
		cap_tin_chi: 'Bước 02 · Phát hành sê-ri Registry',
		ban_tin_chi: 'Bước 03 · Giao dịch chuyển nhượng'
	};

	/** Mã tra thử lấy từ sổ cái thật (/kiem-chung/api/tong-quan); sổ cái trống thì không có chip nào. */
	let mauTraNhanh = $state<{ nhan: string; ma: string }[]>([]);

	let q = $state('');
	let kq = $state<KetQua | null>(null);
	let loi = $state('');
	/** 404: sổ cái không có mã này (khác với lỗi mạng hoặc máy chủ). */
	let khongThay = $state('');
	let dangTra = $state(false);

	async function tra(e?: SubmitEvent) {
		e?.preventDefault();
		const v = q.trim();
		if (!v) return;
		const laSeri = v.includes('-');
		loi = '';
		khongThay = '';
		kq = null;
		dangTra = true;
		history.replaceState(null, '', `?q=${encodeURIComponent(v)}`);
		try {
			const res = await fetch(`/kiem-chung/api/${laSeri ? 'seri' : 'commit'}/${encodeURIComponent(v)}`);
			const laJson = (res.headers.get('content-type') ?? '').includes('application/json');
			const j = laJson ? await res.json().catch(() => null) : null;
			if (res.status === 404) {
				khongThay = j?.loi ?? `Sổ cái không có ${laSeri ? 'tín chỉ' : 'commit'} ${v}`;
			} else if (res.status >= 400 && res.status < 500) {
				loi = j?.loi ?? `Mã tra cứu không hợp lệ (mã ${res.status})`;
			} else if (!res.ok || !j) {
				loi = `Không đọc được sổ cái lúc này (máy chủ trả mã ${res.status}). Hãy thử lại sau.`;
			} else {
				kq = { kieu: laSeri ? 'seri' : 'commit', ...j };
			}
		} catch {
			loi = 'Không kết nối được máy chủ kiểm chứng. Kiểm tra mạng rồi thử lại.';
		} finally {
			dangTra = false;
		}
	}

	function chonMau(ma: string) {
		q = ma;
		tra();
	}

	onMount(() => {
		q = new URLSearchParams(location.search).get('q') ?? '';
		if (q) tra();
		fetch('/kiem-chung/api/tong-quan')
			.then((r) => (r.ok ? r.json() : null))
			.then((d) => {
				if (!d) return;
				const ds: { nhan: string; ma: string }[] = [];
				if (d.seri_moi_nhat) ds.push({ nhan: 'Sê-ri cấp gần nhất', ma: d.seri_moi_nhat });
				if (d.ket_qua_moi_nhat?.commit) ds.push({ nhan: 'Commit MRV gần nhất', ma: d.ket_qua_moi_nhat.commit });
				mauTraNhanh = ds;
			})
			.catch(() => {});
	});

	const soVi = (v: unknown, n = 2) =>
		v === null || v === undefined || v === '' ? '–' : Number(v).toLocaleString('vi-VN', { maximumFractionDigits: n });
	const dinhDangLuc = (s: string) => {
		const m = s.match(/^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}:\d{2}:\d{2})/);
		return m ? `${m[3]}/${m[2]}/${m[1]} · ${m[4]} UTC` : s;
	};
	const TEN_PP: Record<string, string> = {
		'v0.1-rung-ngap-man-ipcc-tier1': 'IPCC 2013 Wetlands Tier 1 (v0.1)'
	};

	const tom = (b: BanGhi) => {
		const d = b.du_lieu as Record<string, any>;
		const pp = d.pha_he?.phuong_phap ? (TEN_PP[d.pha_he.phuong_phap] ?? d.pha_he.phuong_phap) : '–';
		if (b.loai === 'ket_qua_mrv') return `${soVi(d.co2e_tan)} t CO₂e · diện tích tán ${soVi(d.dien_tich_tan_ha)} ha · phương pháp ${pp}`;
		if (b.loai === 'cap_tin_chi') return `${soVi(d.so_luong_tin_chi, 0)} tín chỉ (${d.registry?.seri_tu} → ${d.registry?.seri_den}) cấp cho ${d.chu_so_huu?.ten}`;
		if (b.loai === 'ban_tin_chi') return `${soVi(d.so_luong, 0)} tín chỉ chuyển nhượng: ${d.ben_ban?.ten} → ${d.ben_mua?.ten}`;
		return b.ma_doi_tuong;
	};
	const dsBanGhi = $derived(kq ? (kq.kieu === 'seri' ? kq.su_kien : kq.ban_ghi) : []);
	/** Kết luận toàn vẹn chỉ dựa trên phản hồi của API: sê-ri dùng toan_ven, commit dùng từng bản ghi. */
	const toanVen = $derived(
		kq ? (kq.kieu === 'seri' ? kq.toan_ven : kq.ban_ghi.every((b) => b.sha256_khop && b.con_nguyen_ven)) : false
	);
</script>

<svelte:head><title>Kiểm chứng tín chỉ · CarbonFarm OS</title></svelte:head>

<div class="trang">
	<header class="dau">
		<a class="ten" href="/">
			<img class="logo-anh" src="/nen/logo-transparent.png" alt="Logo CarbonFarm OS" width="36" height="36" />
			<span>CarbonFarm OS</span>
		</a>
		<nav aria-label="Trang chủ">
			<a href="/">← Về trang chủ / Bàn làm việc</a>
			<a href="/#cach-lam">Cách làm</a>
			<a href="/#phuong-phap">Phương pháp</a>
		</nav>
	</header>

	<section class="mo" aria-labelledby="td">
		<div class="mo-trai">
			<div class="huy-hieu-chinh">
				<img class="logo-mini" src="/nen/logo-transparent.png" alt="" width="20" height="20" />
				<span>Cổng Kiểm Chứng Sổ Cái Công Khai</span>
				<span class="cham-xanh"></span>
			</div>
			<h1 id="td">Tra một tín chỉ trên sổ cái</h1>
			<p class="dan">
				Hệ thống đọc trực tiếp bản ghi bất biến trong sổ cái Dolt, tính lại mã băm <code>SHA-256</code> của từng sự kiện
				và đối chiếu chữ ký toàn vẹn. Không cần tài khoản.
			</p>
			{#if mauTraNhanh.length}
			<div class="mau-nhanh">
				<span>Tra thử trên sổ cái:</span>
				{#each mauTraNhanh as m (m.ma)}
					<button type="button" class="chip-mau" class:chon={q === m.ma} onclick={() => chonMau(m.ma)}>
						{m.nhan} (<code>{m.ma.slice(0, 15)}{m.ma.length > 15 ? '…' : ''}</code>)
					</button>
				{/each}
			</div>
			{/if}
		</div>

		<form class="form-tra" onsubmit={tra}>
			<label class="o-nhap">
				Số sê-ri tín chỉ hoặc mã băm commit Dolt
				<input bind:value={q} placeholder="MCK-DM01-26-0000000001" autocomplete="off" spellcheck="false" />
			</label>
			<button class="nut rong" type="submit" disabled={dangTra}>{dangTra ? 'Đang đối chiếu sổ cái…' : 'Kiểm chứng toàn vẹn'}</button>
			{#if loi}<p role="alert" class="loi">{loi}</p>{/if}
		</form>
	</section>

	<main>
		{#if khongThay}
			<section class="ket-luan khong-thay" role="status" aria-labelledby="kt">
				<div class="ket-luan-dau">
					<span class="huy-hieu">Không tìm thấy trên sổ cái</span>
				</div>
				<h2 id="kt">Không có bản ghi.</h2>
				<p>{khongThay}. Kiểm tra lại số sê-ri hoặc mã băm; tín chỉ chưa được cấp sẽ không có trên sổ cái.</p>
			</section>
		{:else if kq}
			<section class="ket-luan" class:hong={!toanVen} aria-labelledby="kl">
				<div class="ket-luan-dau">
					<span class="huy-hieu">
						{#if !toanVen}
							Cảnh báo sai lệch
						{:else}
							Chứng thư sổ cái hợp lệ · Dolt + SHA-256
						{/if}
					</span>
					{#if kq.kieu === 'seri'}
						<span class="nhan {kq.toan_ven ? 'tot' : 'xau'}">
							{kq.toan_ven ? `${kq.su_kien.length}/${kq.su_kien.length} bản ghi khớp SHA-256` : 'Phát hiện bản ghi không khớp'}
						</span>
					{/if}
				</div>

				{#if kq.kieu === 'seri'}
					<h2 id="kl">{kq.toan_ven ? 'Toàn vẹn.' : 'Có bản ghi không khớp.'}</h2>
					<p>
						Tín chỉ <code>{kq.so_seri}</code> hiện thuộc quyền sở hữu của <b>{kq.chu_so_huu_theo_so_cai.ten}</b> (mã số thuế
						<code>{kq.chu_so_huu_theo_so_cai.ma_so_thue}</code>), được truy nguyên qua <b>{kq.su_kien.length}</b> bản ghi nối tiếp trên sổ cái.
					</p>
				{:else}
					<h2 id="kl">Một commit trên sổ cái.</h2>
					<p>Commit <code>{kq.commit}</code> · ghi lúc <b>{dinhDangLuc(kq.luc)}</b><br />{kq.thong_diep}</p>
				{/if}
			</section>

			<section class="chuoi" aria-labelledby="chuoi-td">
				<div class="chuoi-dau">
					<h2 id="chuoi-td">Các bản ghi trong chuỗi phả hệ ({dsBanGhi.length})</h2>
					<p>Mỗi bản ghi được băm lại từ JSON gốc (đã ẩn định danh cá nhân theo quy định bảo mật).</p>
				</div>

				<ol>
					{#each dsBanGhi as b (b.commit + b.ma_doi_tuong)}
						<li>
							<div class="moc-thoi-gian" aria-hidden="true"></div>
							<div class="noi-dung-buoc">
								<div class="dong-dau">
									<div>
										<span class="buoc-nhan">{BUOC_NHAN[b.loai] ?? 'Sự kiện sổ cái'}</span>
										<h3>{LOAI[b.loai] ?? b.loai}</h3>
									</div>
									<span class="nhan" class:tot={b.sha256_khop && b.con_nguyen_ven} class:xau={!b.sha256_khop || !b.con_nguyen_ven}>
										{b.sha256_khop && b.con_nguyen_ven ? 'SHA-256 khớp · Nguyên vẹn' : b.sha256_khop ? 'Đã bị sửa sau' : 'SHA-256 không khớp'}
									</span>
								</div>

								<p class="tom">{tom(b)}</p>

								<div class="thong-tin-bam">
									<div>
										<span>Commit Dolt</span>
										<a href="?q={b.commit}" onclick={(e) => { e.preventDefault(); q = b.commit; tra(); }}><code>{b.commit}</code></a>
									</div>
									<div>
										<span>Thời điểm ghi sổ</span>
										<strong>{dinhDangLuc(b.luc)}</strong>
									</div>
								</div>

								<details>
									<summary>Bản ghi gốc & đối chiếu mã băm SHA-256 (định danh người dùng đã ẩn)</summary>
									<div class="bang-sha">
										<div>
											<span>SHA-256 lưu trong sổ cái</span>
											<code>{b.sha256_so_cai}</code>
										</div>
										<div>
											<span>SHA-256 tính lại trực tiếp</span>
											<code>{b.sha256_tinh_lai}</code>
										</div>
									</div>
									<pre><code>{JSON.stringify(b.du_lieu, null, 2)}</code></pre>
								</details>
							</div>
						</li>
					{/each}
				</ol>
			</section>
		{/if}
	</main>
</div>

<style>
	.trang {
		max-width: 1240px;
		margin: 0 auto;
		padding: 0 var(--le) 96px;
	}
	.dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 24px;
		min-height: 76px;
		border-bottom: 1px solid var(--ke);
	}
	.ten {
		display: inline-flex;
		align-items: center;
		gap: 12px;
		color: var(--muc);
		font: 700 1.25rem var(--serif);
		letter-spacing: -0.02em;
		text-decoration: none;
	}
	.logo-anh {
		display: block;
		width: 36px;
		height: 36px;
		object-fit: contain;
		filter: drop-shadow(0 2px 6px rgb(11 93 76 / 0.18));
	}
	.dau nav {
		display: flex;
		align-items: center;
		gap: 24px;
	}
	.dau nav a {
		color: var(--mo);
		font-size: 0.9375rem;
		font-weight: 500;
		text-decoration: none;
	}
	.dau nav a:hover {
		color: var(--teal);
	}

	/* Khối tra cứu phẳng, không lồng thẻ trong thẻ */
	.mo {
		display: grid;
		grid-template-columns: minmax(0, 1.15fr) minmax(320px, 0.85fr);
		gap: clamp(28px, 4vw, 56px);
		align-items: center;
		padding: clamp(28px, 4vw, 48px) 0;
		border-bottom: 1px solid var(--ke);
	}
	h1 {
		color: var(--muc);
		font-size: clamp(2rem, 3.8vw, 3.125rem);
		line-height: 1.08;
	}
	.huy-hieu-chinh {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		margin-bottom: 14px;
		padding: 5px 14px;
		border: 1px solid var(--teal-vien);
		border-radius: 999px;
		background: var(--teal-nhat);
		color: var(--teal-dam);
		font-size: 0.8125rem;
		font-weight: 600;
	}
	.logo-mini {
		display: block;
		width: 18px;
		height: 18px;
		object-fit: contain;
	}
	.dan {
		max-width: 54ch;
		margin-top: 14px;
		color: var(--mo);
		font-size: 1.0625rem;
		line-height: 1.6;
	}
	.mau-nhanh {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 8px;
		margin-top: 20px;
	}
	.mau-nhanh > span {
		color: var(--mo);
		font-size: 0.8125rem;
		font-weight: 600;
	}
	.chip-mau {
		padding: 6px 12px;
		border: 1px solid var(--ke-dam);
		border-radius: 999px;
		background: #fff;
		color: var(--muc);
		font: 500 0.8125rem var(--sans);
		cursor: pointer;
		transition: border-color 0.15s var(--de), background-color 0.15s var(--de);
	}
	.chip-mau:hover,
	.chip-mau.chon {
		border-color: var(--teal);
		background: var(--teal-nhat);
		color: var(--teal-dam);
	}
	.form-tra {
		display: grid;
		gap: 14px;
		padding: 24px;
		border: 1px solid var(--ke);
		border-radius: 22px;
		background: #fff;
		box-shadow: var(--bong);
	}

	main {
		margin-top: 32px;
	}
	code {
		font-size: 0.85em;
		overflow-wrap: anywhere;
	}

	/* Thẻ chứng thư kết luận sáng trang nhã thay cho khối đen đặc */
	.ket-luan {
		display: grid;
		gap: 12px;
		padding: clamp(24px, 3.5vw, 36px);
		border: 1.5px solid #99d5be;
		border-radius: 26px;
		background: linear-gradient(180deg, #f2fbf7 0%, #e4f4ec 100%);
		color: var(--muc);
		box-shadow: var(--bong);
	}
	.ket-luan.hong {
		border-color: #f3c4bd;
		background: var(--xau-nhat);
	}
	.ket-luan.khong-thay {
		border-color: var(--ke);
		background: #ffffff;
	}
	.ket-luan.khong-thay h2,
	.ket-luan.khong-thay .huy-hieu {
		color: var(--muc);
	}
	.ket-luan-dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 10px;
	}
	.huy-hieu {
		color: var(--teal-dam);
		font-size: 0.75rem;
		font-weight: 700;
		letter-spacing: 0.05em;
		text-transform: uppercase;
	}
	.ket-luan h2 {
		color: var(--teal-dam);
		font-size: clamp(1.75rem, 3vw, 2.5rem);
	}
	.ket-luan.hong h2,
	.ket-luan.hong .huy-hieu {
		color: var(--xau);
	}
	.ket-luan p {
		max-width: 68ch;
		color: var(--muc);
		font-size: 1.0625rem;
		line-height: 1.6;
	}
	.ket-luan code {
		color: var(--teal-dam);
		font-weight: 700;
	}

	/* Chuỗi sự kiện sổ cái */
	.chuoi {
		margin-top: 40px;
	}
	.chuoi-dau {
		margin-bottom: 20px;
	}
	.chuoi-dau h2 {
		font-size: 1.5rem;
	}
	.chuoi-dau p {
		margin-top: 4px;
		color: var(--mo);
		font-size: 0.9375rem;
	}
	ol {
		display: grid;
		gap: 16px;
		margin: 0;
		padding: 0;
		list-style: none;
	}
	li {
		position: relative;
		display: grid;
		grid-template-columns: 24px minmax(0, 1fr);
		gap: 16px;
	}
	.moc-thoi-gian {
		position: relative;
		display: flex;
		justify-content: center;
	}
	.moc-thoi-gian::before {
		content: '';
		width: 14px;
		height: 14px;
		margin-top: 26px;
		border: 3px solid var(--teal);
		border-radius: 50%;
		background: #fff;
		z-index: 1;
	}
	li:not(:last-child) .moc-thoi-gian::after {
		content: '';
		position: absolute;
		top: 40px;
		bottom: -24px;
		width: 2px;
		background: var(--ke-dam);
	}
	.noi-dung-buoc {
		display: grid;
		gap: 12px;
		min-width: 0;
		padding: 24px;
		border: 1px solid var(--ke);
		border-radius: 22px;
		background: #fff;
		box-shadow: var(--bong);
	}
	.dong-dau {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		flex-wrap: wrap;
		gap: 12px;
	}
	.buoc-nhan {
		display: block;
		color: var(--teal);
		font-size: 0.75rem;
		font-weight: 700;
		letter-spacing: 0.04em;
		text-transform: uppercase;
	}
	h3 {
		margin-top: 2px;
		font-size: 1.25rem;
	}
	.tom {
		color: var(--muc);
		font-size: 1rem;
		font-weight: 500;
	}
	.thong-tin-bam {
		display: flex;
		flex-wrap: wrap;
		gap: 16px 32px;
		padding: 12px 0;
		border-top: 1px solid var(--ke);
		border-bottom: 1px solid var(--ke);
		font-size: 0.8125rem;
	}
	.thong-tin-bam > div {
		display: grid;
		gap: 2px;
	}
	.thong-tin-bam span {
		color: var(--mo);
		font-size: 0.75rem;
	}
	.thong-tin-bam a {
		color: var(--teal);
		font-weight: 600;
	}
	summary {
		color: var(--teal-dam);
		font-size: 0.875rem;
		font-weight: 600;
		cursor: pointer;
	}
	.bang-sha {
		display: grid;
		gap: 8px;
		margin-top: 10px;
		padding: 10px 0;
		border-bottom: 1px solid var(--ke);
		font-size: 0.8125rem;
	}
	.bang-sha > div {
		display: grid;
		gap: 2px;
	}
	.bang-sha span {
		color: var(--mo);
		font-size: 0.75rem;
	}
	.bang-sha code {
		color: var(--teal-dam);
		font-weight: 600;
	}
	pre {
		max-height: 20rem;
		overflow: auto;
		margin: 10px 0 0;
		padding: 12px 0 0;
		font-size: 0.8125rem;
	}

	@media (max-width: 860px) {
		.mo {
			grid-template-columns: 1fr;
		}
	}
	@media (max-width: 640px) {
		.dau nav {
			display: none;
		}
		li {
			grid-template-columns: 1fr;
		}
		.moc-thoi-gian {
			display: none;
		}
	}
</style>
