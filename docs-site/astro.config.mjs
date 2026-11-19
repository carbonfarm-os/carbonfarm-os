// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Trang tài liệu: nội dung chép từ docs/, methodology/, README bằng scripts/chep-tai-lieu.mjs (một nguồn sự thật).
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

const REPO = 'https://github.com/carbonfarm-os/carbonfarm-os';

export default defineConfig({
	site: process.env.SITE ?? 'https://carbonfarm-os.github.io',
	base: process.env.BASE ?? '/carbonfarm-os',
	integrations: [
		starlight({
			title: 'CarbonFarm OS',
			description: 'Nền tảng nguồn mở đo carbon rừng ngập mặn, cấp và kiểm chứng tín chỉ cho hợp tác xã.',
			defaultLocale: 'root',
			locales: { root: { label: 'Tiếng Việt', lang: 'vi' } },
			logo: { src: './src/assets/logo.png', alt: 'CarbonFarm OS' },
			social: [{ icon: 'github', label: 'GitHub', href: REPO }],
			editLink: { baseUrl: `${REPO}/edit/main/` },
			customCss: ['./src/styles/giao-dien.css'],
			sidebar: [
				{ label: 'Giới thiệu', link: '/' },
				{ label: 'Dùng thử', link: '/dung-thu/' },
				{ label: 'Hướng dẫn chạy demo', link: '/huong-dan-demo/' },
				{ label: 'Hướng dẫn vận hành HTX', link: '/huong-dan-htx/' },
				{ label: 'Triển khai demo', link: '/trien-khai/' },
				{ label: 'Kiến trúc', link: '/kien-truc/' },
				{ label: 'Viết miền mới (cắm–rút)', link: '/viet-mien/' },
				{ label: 'Phương pháp MRV', items: [{ autogenerate: { directory: 'phuong-phap' } }] },
				{ label: 'Quyết định kiến trúc (ADR)', items: [{ autogenerate: { directory: 'adr' } }] },
				{ label: 'Lộ trình', link: '/lo-trinh/' }
			]
		})
	]
});
