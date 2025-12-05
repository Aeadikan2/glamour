import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import Link from "next/link"

export default function SignUpSuccessPage() {
  return (
    <div className="flex min-h-svh w-full items-center justify-center p-6 md:p-10 bg-gradient-to-br from-primary/5 to-accent/5">
      <div className="w-full max-w-sm">
        <Card className="border-primary/20">
          <CardHeader className="text-center">
            <CardTitle className="text-3xl">Check Your Email</CardTitle>
            <CardDescription>We've sent you a confirmation link</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-6">
            <div className="text-center text-sm text-muted-foreground">
              Please check your email and click the confirmation link to activate your account. Once confirmed, you'll
              be able to log in to your dashboard.
            </div>
            <div className="flex gap-3">
              <Button variant="outline" className="flex-1 bg-transparent" asChild>
                <Link href="/auth/login">Back to Login</Link>
              </Button>
              <Button className="flex-1" asChild>
                <Link href="/">Go Home</Link>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
