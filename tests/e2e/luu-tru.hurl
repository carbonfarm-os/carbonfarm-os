# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Smoke dữ liệu phi cấu trúc (#8): Versity S3 (nội bộ) → danh mục STAC (pgSTAC) → tile TiTiler, qua gateway có JWT.
# Ảnh dùng: du-lieu/mau-cog.tif – COG 256×256 dữ liệu giả, vùng mẫu 105.00–105.05 E, 8.60–8.65 N.

# Tải ảnh lên S3 nội bộ, ký AWS SigV4 bằng khóa do OpenBao sinh
PUT http://s3:7070/anh-ve-tinh/kiem-thu/mau-cog.tif
[Options]
aws-sigv4: aws:amz:us-east-1:s3
user: {{s3_truy_cap}}:{{s3_bi_mat}}
file,du-lieu/mau-cog.tif;
HTTP 200

# Sai khóa → S3 từ chối
PUT http://s3:7070/anh-ve-tinh/kiem-thu/sai-khoa.tif
[Options]
aws-sigv4: aws:amz:us-east-1:s3
user: {{s3_truy_cap}}:sai-bi-mat
file,du-lieu/mau-cog.tif;
HTTP 403

# STAC không token → 401
GET {{gateway}}/stac/collections
HTTP 401

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: client_credentials
client_id: kiem-thu-quan-tri
client_secret: {{kc_secret_qt}}
HTTP 200
[Captures]
tk: jsonpath "$.access_token"

# Thêm collection
POST {{gateway}}/stac/collections
Authorization: Bearer {{tk}}
Content-Type: application/json
{
  "type": "Collection", "id": "kiem-thu-{{newUuid}}", "stac_version": "1.0.0",
  "description": "Collection kiểm thử (dữ liệu giả)", "license": "CC-BY-4.0", "links": [],
  "extent": {"spatial": {"bbox": [[105.0, 8.6, 105.05, 8.65]]}, "temporal": {"interval": [["2026-01-01T00:00:00Z", null]]}}
}
HTTP 201
[Captures]
bo: jsonpath "$.id"

# Thêm item trỏ tới ảnh trên S3
POST {{gateway}}/stac/collections/{{bo}}/items
Authorization: Bearer {{tk}}
Content-Type: application/json
{
  "type": "Feature", "stac_version": "1.0.0", "id": "mau-cog", "collection": "{{bo}}",
  "bbox": [105.0, 8.6, 105.05, 8.65],
  "geometry": {"type": "Polygon", "coordinates": [[[105.0, 8.6], [105.05, 8.6], [105.05, 8.65], [105.0, 8.65], [105.0, 8.6]]]},
  "properties": {"datetime": "2026-10-01T03:00:00Z"},
  "assets": {"anh": {"href": "s3://anh-ve-tinh/kiem-thu/mau-cog.tif", "type": "image/tiff; application=geotiff; profile=cloud-optimized"}},
  "links": []
}
HTTP 201

# Tìm theo vùng: trong vùng → 1, ngoài vùng → 0
GET {{gateway}}/stac/search?collections={{bo}}&bbox=105.01,8.61,105.02,8.62
Authorization: Bearer {{tk}}
HTTP 200
[Asserts]
jsonpath "$.features" count == 1
jsonpath "$.features[0].assets.anh.href" == "s3://anh-ve-tinh/kiem-thu/mau-cog.tif"

GET {{gateway}}/stac/search?collections={{bo}}&bbox=106.0,10.0,106.1,10.1
Authorization: Bearer {{tk}}
HTTP 200
[Asserts]
jsonpath "$.features" count == 0

# TiTiler đọc ảnh từ S3: không token → 401; có token → thông tin + tile PNG
GET {{gateway}}/tiles/cog/info?url=s3://anh-ve-tinh/kiem-thu/mau-cog.tif
HTTP 401

GET {{gateway}}/tiles/cog/info?url=s3://anh-ve-tinh/kiem-thu/mau-cog.tif
Authorization: Bearer {{tk}}
HTTP 200
[Asserts]
jsonpath "$.width" == 256
jsonpath "$.count" == 1

GET {{gateway}}/tiles/cog/tiles/WebMercatorQuad/14/12971/7797.png?url=s3://anh-ve-tinh/kiem-thu/mau-cog.tif
Authorization: Bearer {{tk}}
HTTP 200
[Asserts]
header "Content-Type" == "image/png"
