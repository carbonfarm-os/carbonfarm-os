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
		ket_qua_mrv: 'Kết quả đo MRV đã duyệt',
		cap_tin_chi: 'Cấp tín chỉ (Registry)',
		ban_tin_chi: 'Bán tín chỉ – chuyển quyền sở hữu'
	};

	let q = $state('');
	let kq = $state<KetQua | null>(null);
	let loi = $state('');
	let dangTra = $state(false);

	async function tra(e?: SubmitEvent) {
		e?.preventDefault();
		const v = q.trim();
		if (!v) return;
		const laSeri = v.includes('-');
		loi = '';
		kq = null;
		dangTra = true;
		history.replaceState(null, '', `?q=${encodeURIComponent(v)}`);
		try {
			const res = await fetch(`/kiem-chung/api/${laSeri ? 'seri' : 'commit'}/${encodeURIComponent(v)}`);
			const j = await res.json().catch(() => ({ loi: `Máy chủ trả mã ${res.status}` }));
			if (!res.ok) throw new Error(j.loi ?? `Máy chủ trả mã ${res.status}`);
			kq = { kieu: laSeri ? 'seri' : 'commit', ...j };
		} catch (err) {
			loi = (err as Error).message;
		} finally {
			dangTra = false;
		}
	}

	onMount(() => {
		q = new URLSearchParams(location.search).get('q') ?? '';
		if (q) tra();
	});

	const tom = (b: BanGhi) => {
		const d = b.du_lieu as Record<string, any>;
		if (b.loai === 'ket_qua_mrv') return `${d.co2e_tan} t CO₂e · tán ${d.dien_tich_tan_ha} ha · phương pháp ${d.pha_he?.phuong_phap}`;
		if (b.loai === 'cap_tin_chi') return `${d.so_luong_tin_chi} tín chỉ ${d.registry?.seri_tu} → ${d.registry?.seri_den} cho ${d.chu_so_huu?.ten}`;
		if (b.loai === 'ban_tin_chi') return `${d.so_luong} tín chỉ: ${d.ben_ban?.ten} → ${d.ben_mua?.ten}`;
		return b.ma_doi_tuong;
	};
	const dsBanGhi = $derived(kq ? (kq.kieu === 'seri' ? kq.su_kien : kq.ban_ghi) : []);
</script>

<svelte:head><title>Kiểm chứng sổ cái · CarbonFarm OS</title></svelte:head>

<header>
	<a href="/"><strong>CarbonFarm OS</strong></a>
	<span>Kiểm chứng công khai</span>
</header>

<main>
	<h1>Kiểm chứng tín chỉ trên sổ cái</h1>
	<p>
		Nhập <b>số sê-ri tín chỉ</b> (ví dụ <code>MCK-DM01-26-0000000001</code>) hoặc <b>mã băm commit</b> của sổ cái Dolt.
		Hệ thống tính lại SHA-256 của từng bản ghi và cho biết bản ghi còn nguyên vẹn hay không. Không cần đăng nhập.
	</p>
	<form onsubmit={tra}>
		<input bind:value={q} aria-label="Số sê-ri hoặc mã băm commit" placeholder="Số sê-ri hoặc mã băm commit" />
		<button type="submit" disabled={dangTra}>{dangTra ? 'Đang tra…' : 'Kiểm chứng'}</button>
	</form>

	{#if loi}<p role="alert" class="loi">{loi}</p>{/if}

	{#if kq}
		{#if kq.kieu === 'seri'}
			<section class="tong" class:hong={!kq.toan_ven}>
				<b>{kq.toan_ven ? '✔ Toàn vẹn' : '✘ Có bản ghi không khớp'}</b> – tín chỉ {kq.so_seri}<br />
				Chủ sở hữu theo sổ cái: <b>{kq.chu_so_huu_theo_so_cai.ten}</b> (MST {kq.chu_so_huu_theo_so_cai.ma_so_thue})
			</section>
		{:else}
			<section class="tong">
				Commit <code>{kq.commit}</code> · {kq.luc}<br />
				<small>{kq.thong_diep}</small>
			</section>
		{/if}
		<ol>
			{#each dsBanGhi as b (b.commit + b.ma_doi_tuong)}
				<li>
					<div class="dau">
						<b>{LOAI[b.loai] ?? b.loai}</b>
						<span class="nhan" class:hong={!b.sha256_khop || !b.con_nguyen_ven}>
							{b.sha256_khop && b.con_nguyen_ven ? 'SHA-256 khớp' : b.sha256_khop ? 'Đã bị sửa sau' : 'SHA-256 KHÔNG khớp'}
						</span>
					</div>
					<p>{tom(b)}</p>
					<small>Commit <a href="?q={b.commit}" onclick={(e) => { e.preventDefault(); q = b.commit; tra(); }}><code>{b.commit}</code></a> · {b.luc}</small>
					<details>
						<summary>Bản ghi gốc (định danh người dùng đã ẩn)</summary>
						<p><small>SHA-256 sổ cái: <code>{b.sha256_so_cai}</code><br />SHA-256 tính lại: <code>{b.sha256_tinh_lai}</code></small></p>
						<pre>{JSON.stringify(b.du_lieu, null, 2)}</pre>
					</details>
				</li>
			{/each}
		</ol>
	{/if}
</main>

<style>
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
	header a {
		color: #fff;
		text-decoration: none;
		flex: 1;
	}
	main {
		max-width: 52rem;
		margin: 0 auto;
		padding: 1rem;
	}
	h1 {
		font-size: 1.4rem;
	}
	form {
		display: flex;
		gap: 0.5rem;
		margin: 1rem 0;
	}
	input {
		flex: 1;
		min-width: 0;
		font: inherit;
		padding: 0.45rem 0.6rem;
		border: 1px solid #b7c9b2;
		border-radius: 6px;
		background: #fff;
		color: #1b2b22;
	}
	button {
		font: inherit;
		padding: 0.45rem 1rem;
		border: 0;
		border-radius: 6px;
		background: #95d5b2;
		color: #1b4332;
		cursor: pointer;
	}
	.tong {
		padding: 0.7rem 0.9rem;
		border-radius: 8px;
		background: #1b4332;
		color: #fff;
		overflow-wrap: anywhere;
	}
	.tong.hong {
		background: #7a1c17;
	}
	ol {
		padding-left: 1.2rem;
	}
	li {
		margin: 0.8rem 0;
		padding: 0.6rem 0.8rem;
		border: 1px solid #cfdccb;
		border-radius: 8px;
		background: #fff;
		overflow-wrap: anywhere;
	}
	.dau {
		display: flex;
		justify-content: space-between;
		gap: 0.5rem;
	}
	.nhan {
		font-size: 0.75rem;
		padding: 0.1rem 0.5rem;
		border-radius: 999px;
		background: #d8f3dc;
		color: #1b4332;
		white-space: nowrap;
	}
	.nhan.hong {
		background: #fde2e1;
		color: #7a1c17;
	}
	.loi {
		padding: 0.5rem 0.7rem;
		border-radius: 6px;
		background: #fde2e1;
		color: #7a1c17;
	}
	pre {
		max-height: 18rem;
		overflow: auto;
		padding: 0.5rem;
		background: #f4f7f2;
		border-radius: 6px;
		font-size: 0.72rem;
	}
	code {
		font-size: 0.8rem;
	}
</style>
