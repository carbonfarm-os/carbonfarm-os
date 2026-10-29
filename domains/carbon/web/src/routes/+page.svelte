<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<script lang="ts">
	import 'maplibre-gl/dist/maplibre-gl.css';
	import { onMount } from 'svelte';
	import { Map as BanDo, NavigationControl } from 'maplibre-gl';
	import { batDauDangNhap, dangXuat, nguoiDung, tokenHienTai } from '#lib/dang-nhap.ts';
	import { goiGraphql } from '#lib/graphql.ts';

	const token = tokenHienTai();
	const nd = token ? nguoiDung(token) : null;
	let soGhiChu = $state<number | null>(null);
	let loi = $state('');
	let khungBanDo: HTMLDivElement;

	onMount(() => {
		// Nền OpenStreetMap (dữ liệu ODbL, ghi nguồn); vùng mẫu rừng ngập mặn ven biển Cà Mau.
		const banDo = new BanDo({
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
			center: [105.03, 8.63],
			zoom: 10
		});
		banDo.addControl(new NavigationControl(), 'top-right');
		if (token) {
			goiGraphql<{ allGhiChuMaus: { totalCount: number } }>(token, '{ allGhiChuMaus { totalCount } }')
				.then((d) => (soGhiChu = d.allGhiChuMaus.totalCount))
				.catch((e: Error) => (loi = e.message));
		}
		return () => banDo.remove();
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
	<div class="ban-do" bind:this={khungBanDo} aria-label="Bản đồ vùng mẫu rừng ngập mặn"></div>
	{#if nd}
		<p>
			Kết nối API nền tảng:
			{#if loi}<span role="alert">{loi}</span>
			{:else if soGhiChu === null}đang tải…
			{:else}đọc được {soGhiChu} ghi chú mẫu theo quyền của bạn.{/if}
		</p>
	{:else}
		<p>Đăng nhập để xem dữ liệu của hợp tác xã.</p>
	{/if}
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
		padding: 1rem;
	}
	.ban-do {
		height: 70vh;
		border-radius: 8px;
		background: #dfe8dc;
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
</style>
