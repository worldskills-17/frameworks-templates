export default function Home() {
  return (
    <div style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1 style={{ fontSize: '2rem', fontWeight: 'bold' }}>
        Next.js + Prisma - It works!
      </h1>
      <p style={{ marginTop: '1rem', color: '#666' }}>
        API: <code>GET /api/users</code>, <code>POST /api/users</code> (JSON body:{' '}
        <code>{'{ "email": "...", "name": "..." }'}</code>)
      </p>
    </div>
  );
}
