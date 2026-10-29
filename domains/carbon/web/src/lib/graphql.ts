// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Gọi API GraphQL của Tầng 1 qua gateway (/graphql) bằng token của người dùng; quyền do RLS trong CSDL quyết định.
import type { Token } from './dang-nhap.ts';

/**
 * Lỗi nghiệp vụ do CSDL trả (SQLSTATE bắt đầu bằng "U", ví dụ UC005 chồng lấn): thông báo tiếng Việt viết sẵn trong CSDL,
 * hiện nguyên văn cho người dùng kèm gợi ý. Lỗi khác bị nền tảng che, chỉ hiện câu chung.
 */
export class LoiNghiepVu extends Error {
	constructor(
		message: string,
		readonly ma: string,
		readonly goiY?: string
	) {
		super(message);
	}
}

export async function goiGraphql<T>(token: Token, query: string, variables?: Record<string, unknown>): Promise<T> {
	const res = await fetch('/graphql', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token.access_token}` },
		body: JSON.stringify({ query, variables })
	});
	if (res.status === 401) throw new Error('Phiên đăng nhập đã hết hạn, hãy đăng nhập lại');
	const j = await res.json().catch(() => null);
	const loi = j?.errors?.[0];
	if (loi) {
		const ma = loi.extensions?.code;
		if (typeof ma === 'string' && ma.startsWith('U')) throw new LoiNghiepVu(loi.message, ma, loi.extensions?.hint);
		throw new Error('Máy chủ từ chối yêu cầu');
	}
	if (!res.ok) throw new Error(`Gateway trả mã ${res.status}`);
	return j.data as T;
}
