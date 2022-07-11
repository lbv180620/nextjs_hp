// サーバーサイドのfetchだから、node-fetchを使用
import fetch from 'node-fetch';

// endpoint
const apiUrl = 'https://jsonplaceholder.typicode.com/posts';

/**
 * URL オブジェクト
 * https://ja.javascript.info/url
 */
export const getAllPostsData = async () => {
  const res = await fetch(new URL(apiUrl));
  const posts = await res.json();
  return posts;
};
