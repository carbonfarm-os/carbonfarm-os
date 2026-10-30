// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Bản đồ dùng chung: nền là ảnh Sentinel-2 màu thật của vùng mẫu (tệp tĩnh, chạy được khi không có Internet),
// ngoài vùng ảnh là nền sương. Lô thường viền trắng nét đứt; lô đang chọn tô và viền hổ phách trên viền mòng két đậm.
import { setWorkerUrl, type ExpressionSpecification, type Map as BanDo, type StyleSpecification } from 'maplibre-gl';
import diaChiWorker from 'maplibre-gl/dist/maplibre-gl-worker.mjs?url';

// MapLibre 6 tìm worker theo đường dẫn tương đối với bundle chính; Vite không chép tệp đó vào bản build nên mọi
// nguồn GeoJSON (ranh giới lô) không hiện. Xuất worker thành tệp tĩnh và chỉ đường cho MapLibre.
setWorkerUrl(diaChiWorker);

export type Polygon = { type: 'Polygon'; coordinates: [number, number][][] };

/** Cảnh S2C_T48PVQ_20260414T033318_L2A, asset visual, cắt 104.735–104.835 E, 8.595–8.675 N. */
export const NEN = {
	url: '/nen/mui-ca-mau-s2-20260414.webp',
	toaDo: [
		[104.735, 8.675],
		[104.835, 8.675],
		[104.835, 8.595],
		[104.735, 8.595]
	] as [[number, number], [number, number], [number, number], [number, number]],
	ghiNguon: 'Ảnh nền: Sentinel-2, 14/04/2026 – chứa dữ liệu Copernicus Sentinel đã qua xử lý'
};

export function kieuBanDo(): StyleSpecification {
	return {
		version: 8,
		sources: {
			nen: { type: 'image', url: NEN.url, coordinates: NEN.toaDo }
		},
		layers: [
			{ id: 'giay', type: 'background', paint: { 'background-color': '#dfe3e1' } },
			{ id: 'nen', type: 'raster', source: 'nen', paint: { 'raster-fade-duration': 0 } }
		]
	};
}

const CHON: ExpressionSpecification = ['boolean', ['get', 'chon'], false];

/** Nguồn + lớp lô: nền mờ, viền trắng nét đứt; lô chọn tô hổ phách, viền hổ phách trên nền mòng két để nổi trên ảnh. */
export function themLopLo(b: BanDo, nguon = 'lo'): void {
	b.addSource(nguon, { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });
	b.addLayer({
		id: `${nguon}-nen`,
		type: 'fill',
		source: nguon,
		paint: { 'fill-color': ['case', CHON, '#ecba82', '#ffffff'], 'fill-opacity': ['case', CHON, 0.3, 0.12] }
	});
	b.addLayer({
		id: `${nguon}-vien`,
		type: 'line',
		source: nguon,
		filter: ['!', CHON],
		paint: { 'line-color': '#ffffff', 'line-width': 2, 'line-dasharray': [3, 2] }
	});
	b.addLayer({
		id: `${nguon}-co-vien`,
		type: 'line',
		source: nguon,
		filter: CHON,
		layout: { 'line-join': 'round' },
		paint: { 'line-color': '#024f46', 'line-width': 7 }
	});
	b.addLayer({
		id: `${nguon}-co`,
		type: 'line',
		source: nguon,
		filter: CHON,
		layout: { 'line-join': 'round' },
		paint: { 'line-color': '#ecba82', 'line-width': 3.5 }
	});
}

export function tam(p: Polygon): [number, number] {
	const v = p.coordinates[0].slice(0, -1);
	return [v.reduce((t, d) => t + d[0], 0) / v.length, v.reduce((t, d) => t + d[1], 0) / v.length];
}
