export default function Home() {
  return (
    <main style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '2rem',
      fontFamily: 'system-ui, -apple-system, sans-serif',
    }}>
      <div style={{
        textAlign: 'center',
        maxWidth: '640px',
      }}>
        <p style={{
          fontSize: '0.875rem',
          letterSpacing: '0.1em',
          textTransform: 'uppercase',
          color: '#60a5fa',
          marginBottom: '1rem',
        }}>
          Axiom / Consumer Apps
        </p>

        <h1 style={{
          fontSize: 'clamp(2.5rem, 6vw, 4rem)',
          fontWeight: 700,
          lineHeight: 1.1,
          marginBottom: '1.5rem',
        }}>
          KeepTrack
        </h1>

        <p style={{
          fontSize: '1.25rem',
          lineHeight: 1.6,
          color: '#a1a1aa',
          marginBottom: '2rem',
        }}>
          Your warranties, return windows, and purchase records — automatically organized so you never miss a claim.
        </p>

        <div style={{
          display: 'inline-block',
          padding: '0.5rem 1.25rem',
          borderRadius: '9999px',
          border: '1px solid #60a5fa',
          color: '#60a5fa',
          fontSize: '0.875rem',
          fontWeight: 500,
          marginBottom: '3rem',
        }}>
          S2 Define
        </div>

        <p style={{
          fontSize: '0.75rem',
          color: '#52525b',
        }}>
          A BigClaw AI product
        </p>
      </div>
    </main>
  )
}
