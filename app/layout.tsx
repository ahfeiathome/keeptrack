import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'KeepTrack — Coming Soon',
  description: 'Your warranties, return windows, and purchase records — automatically organized so you never miss a claim.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
