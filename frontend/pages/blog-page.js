import Layout from '../components/Layout';
import Post from '../components/Post';
import { getAllPostsData } from '../lib/posts';

const BlogPage = ({ posts }) => {
  return (
    <Layout title="Blog">
      <ul className="m-10">
        {posts &&
          posts.map((post, index) => (
            <Post key={post.id.toString() + index.toString()} post={post} />
          ))}
      </ul>
    </Layout>
  );
};

export default BlogPage;

/**
 * ビルド時にサーバーサイドで一度だけ実行される。
 *
 * 戻り値はコンポーネントに渡す。
 */
export const getStaticProps = async () => {
  const posts = await getAllPostsData();
  return {
    props: { posts },
  };
};

/**
 * getStaticProps
 *
 * ・必ずServer sideで実行される
 * ・pages内でのみ使用可能
 * ・npm run dev (development) → ユーザーのリクエスト毎(前)に実行される
 * ・npm start (production) → ビルド時に実行される
 * ・getStaticPropsを持つページは、Pre-renderingでHTMLファイルだけでなくJSONファイルも生成する
 *
 * getServerSidePropsとの違い：
 * getServerSidePropsは、リクエストのタイミングで実行されます！
 * 開発環境でも本番環境でも等しくリクエスト毎に実行を行います！
 * getServerSidePropsは、リクエスト毎に結果を出力します。
 */

/**
 * Dynamic Routes
 *
 * posts/[id].js
 *
 * Next.jsではフォルダの構造とファイル名が直接URLのパスに対応している。
 */

/**
 * Dynamic routes (詳細ページのpre-renderingの流れ)
 *
 * 1. getStaticPaths() → idの一覧を取得
 * APIのendpointにアクセスしてどういったidがあるかの一覧を取得
 * 今回は1~100のidを取得して来る。
 *
 * 2. getStaticProps()
 * → 各idを使って個別データを取得
 * https://jsonpalce.../posts/id
 *
 * 3. 取得したデータをpropsでReact Componentに渡してpre-fetching (HTML事前生成)
 * SSGを100個分作る。
 */
