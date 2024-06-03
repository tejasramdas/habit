include("stim.jl")

using ThreadPools

led=led_init()

led.high()
sleep(0.5)
led.low()

t=@tspawnat 2 flash(10,0.01,1,led,0)

schedule(t,:stop,error=true)

