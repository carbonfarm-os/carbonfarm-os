<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<script lang="ts">
	import { goto } from '$app/navigation';
	import { hoanTatDangNhap } from '#lib/dang-nhap.ts';

	let loi = $state('');
	hoanTatDangNhap(new URL(location.href))
		.then(() => goto('/', { replaceState: true }))
		.catch((e: Error) => (loi = e.message));
</script>

<main>
	{#if loi}
		<p role="alert" class="loi">{loi} <a href="/">Về trang chủ</a></p>
	{:else}
		<p role="status">Đang đăng nhập…</p>
	{/if}
</main>

<style>
	main {
		display: grid;
		place-items: center;
		min-height: 100svh;
		padding: var(--le);
		color: var(--muc);
		font: 500 1.25rem var(--serif);
	}
</style>
