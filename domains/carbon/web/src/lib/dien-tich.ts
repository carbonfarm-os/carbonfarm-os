// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Diện tích gần đúng của đa giác kinh/vĩ độ để người vẽ thấy ngay (công thức diện tích cầu, bán kính WGS84 trung bình).
// Chỉ để hiển thị: số chính thức do CSDL tính (PostGIS, geography) khi đăng ký.
const R = 6371008.8;
const rad = (d: number) => (d * Math.PI) / 180;

export function dienTichHa(vong: [number, number][]): number {
	if (vong.length < 3) return 0;
	let tong = 0;
	for (let i = 0; i < vong.length; i++) {
		const [x1, y1] = vong[i];
		const [x2, y2] = vong[(i + 1) % vong.length];
		tong += rad(x2 - x1) * (2 + Math.sin(rad(y1)) + Math.sin(rad(y2)));
	}
	return Math.abs((tong * R * R) / 2) / 10000;
}
