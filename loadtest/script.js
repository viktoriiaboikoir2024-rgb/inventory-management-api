import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL;
const N = parseInt(__ENV.VUS || '50');   // N віртуальних користувачів на сталому етапі

export const options = {
  stages: [
    { duration: '3m', target: N },  // наростання 0 -> N
    { duration: '5m', target: N },  // стале навантаження
    { duration: '2m', target: 0 },  // спад до нуля
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
  },
  // med = p50
  summaryTrendStats: ['avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

const CATEGORIES = ['tools', 'electronics', 'furniture', 'food', 'clothing'];
const JSON_HEADERS = { headers: { 'Content-Type': 'application/json' } };

export default function () {
  const category = CATEGORIES[Math.floor(Math.random() * CATEGORIES.length)];

  // 1 запис
  const created = http.post(
    `${BASE_URL}/items`,
    JSON.stringify({
      name: `item-${__VU}-${__ITER}`,
      category: category,
      quantity: Math.floor(Math.random() * 100),
      price: Math.round(Math.random() * 10000) / 100 + 1,
    }),
    { ...JSON_HEADERS, tags: { name: 'POST /items' } }
  );
  const ok = check(created, { 'створено (201)': (r) => r.status === 201 });
  if (!ok) { sleep(1); return; }
  const id = created.json('id');

  // 9 читань
  for (let i = 0; i < 2; i++) {
    check(http.get(`${BASE_URL}/items?limit=50`, { tags: { name: 'GET /items' } }),
      { 'список 200': (r) => r.status === 200 });
  }
  for (let i = 0; i < 3; i++) {
    check(http.get(`${BASE_URL}/items?category=${category}&limit=50`,
      { tags: { name: 'GET /items?category' } }),
      { 'за категорією 200': (r) => r.status === 200 });
  }
  for (let i = 0; i < 4; i++) {
    check(http.get(`${BASE_URL}/items/${id}`, { tags: { name: 'GET /items/{id}' } }),
      { 'позиція 200': (r) => r.status === 200 });
  }

  sleep(0.5); // пауза «користувача»
}