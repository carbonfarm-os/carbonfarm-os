// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Đăng nhập Keycloak bằng Authorization Code + PKCE (S256), viết tay bằng WebCrypto, không thư viện OIDC.
// Keycloak và web cùng origin qua gateway (/auth và /), client công khai "web" của realm dxos.
const REALM = '/auth/realms/dxos/protocol/openid-connect';
const CLIENT_ID = 'web';
const KHOA = { verifier: 'pkce-verifier', state: 'pkce-state', token: 'token' } as const;

export interface Token {
	access_token: string;
	id_token?: string;
	expires_at: number;
}

function base64url(bytes: Uint8Array): string {
	let s = '';
	for (const b of bytes) s += String.fromCharCode(b);
	return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function ngauNhien(n: number): string {
	return base64url(crypto.getRandomValues(new Uint8Array(n)));
}

async function thachThuc(verifier: string): Promise<string> {
	const bam = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier));
	return base64url(new Uint8Array(bam));
}

function duongQuayVe(): string {
	return `${location.origin}/dang-nhap/xong`;
}

export async function batDauDangNhap(): Promise<void> {
	const verifier = ngauNhien(48);
	const state = ngauNhien(16);
	sessionStorage.setItem(KHOA.verifier, verifier);
	sessionStorage.setItem(KHOA.state, state);
	const q = new URLSearchParams({
		client_id: CLIENT_ID,
		response_type: 'code',
		scope: 'openid',
		redirect_uri: duongQuayVe(),
		state,
		code_challenge: await thachThuc(verifier),
		code_challenge_method: 'S256'
	});
	location.assign(`${REALM}/auth?${q}`);
}

/** Đổi code lấy token sau khi Keycloak chuyển về /dang-nhap/xong. */
export async function hoanTatDangNhap(url: URL): Promise<Token> {
	const code = url.searchParams.get('code');
	const state = url.searchParams.get('state');
	const verifier = sessionStorage.getItem(KHOA.verifier);
	if (!code || !verifier || state !== sessionStorage.getItem(KHOA.state)) {
		throw new Error('Phiên đăng nhập không hợp lệ, hãy đăng nhập lại.');
	}
	sessionStorage.removeItem(KHOA.verifier);
	sessionStorage.removeItem(KHOA.state);
	const res = await fetch(`${REALM}/token`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
		body: new URLSearchParams({
			grant_type: 'authorization_code',
			client_id: CLIENT_ID,
			code,
			redirect_uri: duongQuayVe(),
			code_verifier: verifier
		})
	});
	if (!res.ok) throw new Error(`Không lấy được token (mã ${res.status}).`);
	const j = await res.json();
	const token: Token = {
		access_token: j.access_token,
		id_token: j.id_token,
		expires_at: Date.now() + j.expires_in * 1000
	};
	sessionStorage.setItem(KHOA.token, JSON.stringify(token));
	return token;
}

export function tokenHienTai(): Token | null {
	const t = sessionStorage.getItem(KHOA.token);
	if (!t) return null;
	const token = JSON.parse(t) as Token;
	return token.expires_at > Date.now() + 10_000 ? token : null;
}

/** Thông tin hiển thị lấy từ payload JWT (đã được gateway và máy chủ kiểm chữ ký khi gọi API). */
export function nguoiDung(token: Token): { ten: string; vai: string[] } {
	const nhiPhan = atob(token.access_token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/'));
	const p = JSON.parse(new TextDecoder().decode(Uint8Array.from(nhiPhan, (c) => c.charCodeAt(0))));
	const ten = [p.given_name, p.family_name].filter(Boolean).join(' ') || p.preferred_username || 'Người dùng';
	return { ten, vai: p.realm_access?.roles ?? [] };
}

export function dangXuat(): void {
	const token = tokenHienTai();
	sessionStorage.removeItem(KHOA.token);
	const q = new URLSearchParams({ client_id: CLIENT_ID, post_logout_redirect_uri: `${location.origin}/` });
	if (token?.id_token) q.set('id_token_hint', token.id_token);
	location.assign(`${REALM}/logout?${q}`);
}
