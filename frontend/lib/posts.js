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

/**
 * idの一覧を取得
 */
export const getAllPostIds = async () => {
  const res = await fetch(new URL(apiUrl));
  const posts = await res.json();

  // return posts.map((post) => {
  //   return {
  //     params: {
  //       id: String(post.id),
  //     },
  //   };
  // });
  return posts.map((post) => ({
    /**
     * getStaticPathsは必ずフィールドの名前にparamsと付けなければならない。
     */
    params: {
      id: String(post.id),
    },
  }));
};

/**
 * 個別のデータを取得
 */
export const getPostData = async (id) => {
  const res = await fetch(new URL(`${apiUrl}/${id}/`));
  const post = await res.json();

  // {post: post}
  return post;
};
