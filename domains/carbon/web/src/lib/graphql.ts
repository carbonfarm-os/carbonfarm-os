// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Gọi API GraphQL của Tầng 1 qua gateway (/graphql) bằng token của người dùng; quyền do RLS trong CSDL quyết định.
import type { Token } from './dang-nhap.ts';

export async function goiGraphql<T>(token: Token, query: string, variables?: Record<string, unknown>): Promise<T> {
	const res = await fetch('/graphql', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token.access_token}` },
		body: JSON.stringify({ query, variables })
	});
	if (!res.ok) throw new Error(`Gateway trả mã ${res.status}`);
	const j = await res.json();
	if (j.errors?.length) throw new Error('Máy chủ từ chối yêu cầu');
	return j.data as T;
}
