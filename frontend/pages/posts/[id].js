import Link from 'next/link';
import Layout from '../../components/Layout';
import { getAllPostIds, getPostData } from '../../lib/posts';

const Post = ({ post }) => {
  if (!post) {
    return <div>Loading...</div>;
  }

  return (
    <Layout title={post.title}>
      <p className="m-4">
        {'ID : '}
        {post.id}
      </p>
      <p className="mb-8 text-xl font-bold">{post.title}</p>
      <p className="px-10">{post.body}</p>

      <Link href="/blog-page">
        <div className="mt-12 flex cursor-pointer">
          <svg
            className="mr-3 h-6 w-6"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              d="M11 19l-7-7 7-7m8 14l-7-7 7-7"
            ></path>
          </svg>
          <span>Back to blog-page</span>
        </div>
      </Link>
    </Layout>
  );
};

export default Post;

export const getStaticPaths = async () => {
  // ビルド時にAPIのendpointにアクセスして必要なidの一覧を取得
  const paths = await getAllPostIds();

  return {
    paths,
    /**
     * 今回は1~100番まであって詳細ページが100個表示されるが、例えば101番にユーザーがアクセスした時の挙動をどうするのかを決めるのがこのオプション。
     *
     * falseにした場合は101番にアクセスした場合は、404 Not Foundを返すようになっている。
     *
     * 動的にブログのコンテンツが増えていくような場合は、trueすることで対応できる。
     */
    fallback: false,
  };
};

export const getStaticProps = async ({ params }) => {
  const post = await getPostData(params.id);

  return {
    props: {
      post,
    },
  };
};
