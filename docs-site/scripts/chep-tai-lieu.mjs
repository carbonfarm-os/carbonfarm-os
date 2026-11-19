// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Chép tài liệu Markdown của repo vào src/content/docs/ cho Starlight (thư mục sinh ra, ngoài git).
// Mỗi tệp: lấy tiêu đề # đầu tiên làm title, bỏ chú thích SPDX, sửa liên kết tương đối: tới trang có trên site thì
// trỏ trang đó, còn lại trỏ tệp trên GitHub. Ảnh trong docs/images và logo chép kèm.
import { cpSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, normalize, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const GOC = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const DICH = join(GOC, 'docs-site', 'src', 'content', 'docs');
const REPO = 'https://github.com/carbonfarm-os/carbonfarm-os/blob/main/';
const BASE = (process.env.BASE ?? '/carbonfarm-os').replace(/\/$/, '');

// tệp nguồn (tính từ gốc repo) → đường dẫn trang
const TRANG = new Map([
	['README.md', ''],
	['docs/thu-nghiem.md', 'dung-thu'],
	['docs/demo/huong-dan-demo.md', 'huong-dan-demo'],
	['docs/demo/huong-dan-htx.md', 'huong-dan-htx'],
	['docs/trien-khai.md', 'trien-khai'],
	['docs/architecture.md', 'kien-truc'],
	['docs/viet-mien.md', 'viet-mien'],
	['docs/roadmap.md', 'lo-trinh'],
	['methodology/README.md', 'phuong-phap'],
	['methodology/v0.1-rung-ngap-man-ipcc-tier1.md', 'phuong-phap/v0-1-rung-ngap-man-ipcc-tier1']
]);
for (const f of readdirSync(join(GOC, 'docs/adr')).filter((f) => f.endsWith('.md') && !f.startsWith('0000'))) {
	TRANG.set(`docs/adr/${f}`, `adr/${f.replace(/\.md$/, '')}`);
}

function suaLienKet(noiDung, nguon) {
	return noiDung.replace(/\]\((?!https?:|#|mailto:)([^)\s]+)\)/g, (m, dich) => {
		const [duong, neo] = dich.split('#');
		const tuyetDoi = normalize(join(dirname(nguon), duong)).replace(/\\/g, '/');
		if (tuyetDoi.startsWith('docs/images/')) return `](${BASE}/anh/${relative('docs/images', tuyetDoi)})`;
		const trang = TRANG.get(tuyetDoi);
		const url = trang !== undefined ? `${BASE}/${trang}${trang ? '/' : ''}` : REPO + tuyetDoi;
		return `](${url}${neo ? `#${neo}` : ''})`;
	}).replace(/src="(?!https?:)([^"]+)"/g, (m, duong) => {
		const tuyetDoi = normalize(join(dirname(nguon), duong)).replace(/\\/g, '/');
		return tuyetDoi.startsWith('docs/images/') ? `src="${BASE}/anh/${relative('docs/images', tuyetDoi)}"` : m;
	});
}

rmSync(DICH, { recursive: true, force: true });
for (const [nguon, trang] of TRANG) {
	let nd = readFileSync(join(GOC, nguon), 'utf8').replace(/<!--\s*SPDX-[^>]*-->\n?/g, '');
	// "Kiến trúc · Architecture" → "Kiến trúc"; "0003 · Sổ cái…" (ADR) giữ nguyên
	const dau = (nd.match(/^#\s+(.+)$/m)?.[1] ?? trang).split(' · ');
	const tieuDe = (/^\d+$/.test(dau[0]) ? dau.join(' · ') : dau[0]).trim();
	nd = nd.replace(/^#\s+.+\n/m, '');
	nd = suaLienKet(nd, nguon);
	const tep = join(DICH, trang === '' ? 'index.md' : `${trang}.md`);
	mkdirSync(dirname(tep), { recursive: true });
	writeFileSync(tep, `---\ntitle: ${JSON.stringify(tieuDe)}\neditUrl: ${JSON.stringify(`${REPO.replace('/blob/', '/edit/')}${nguon}`)}\n---\n${nd}`);
}
cpSync(join(GOC, 'docs/images'), join(GOC, 'docs-site/public/anh'), { recursive: true });
mkdirSync(join(GOC, 'docs-site/src/assets'), { recursive: true });
cpSync(join(GOC, 'docs/images/logo.png'), join(GOC, 'docs-site/src/assets/logo.png'));
console.log(`Đã chép ${TRANG.size} trang vào ${relative(GOC, DICH)}`);
