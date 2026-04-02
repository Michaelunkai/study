import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-lg text-sm font-medium transition-all duration-150 ease-out focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:pointer-events-none disabled:opacity-40 select-none [&_svg]:pointer-events-none [&_svg]:shrink-0 active:scale-[0.97]',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/85 shadow-sm hover:shadow',
        secondary: 'bg-secondary text-muted-foreground hover:bg-muted hover:text-foreground',
        ghost: 'text-muted-foreground hover:text-foreground hover:bg-secondary/80',
        outline:
          'border border-border bg-transparent text-muted-foreground hover:text-foreground hover:bg-secondary/60 hover:border-border/80',
        destructive:
          'text-red-400 bg-red-500/10 border border-red-500/20 hover:bg-red-500/25 hover:text-red-300',
        success:
          'bg-green-500/15 text-green-400 border border-green-500/25 hover:bg-green-500/25 hover:text-green-300',
        link: 'text-primary underline-offset-4 hover:underline p-0 h-auto',
      },
      size: {
        xs: 'h-7 px-2.5 text-xs rounded-md',
        sm: 'h-8 px-3 text-xs rounded-md',
        md: 'h-9 px-4 text-sm',
        lg: 'h-10 px-6 text-sm font-semibold',
        'icon-xs': 'h-7 w-7 rounded-md',
        // icon sizes use min-h/min-w to ensure 44px touch targets on Android/iOS
        'icon-sm': 'h-8 w-8 min-h-[44px] min-w-[44px] md:min-h-[32px] md:min-w-[32px]',
        icon: 'h-9 w-9 min-h-[44px] min-w-[44px] md:min-h-[36px] md:min-w-[36px]',
        'icon-lg': 'h-10 w-10 min-h-[44px] min-w-[44px] md:min-h-[40px] md:min-w-[40px]',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
    },
  }
)

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = 'Button'

export { Button, buttonVariants }
export type { ButtonProps }
