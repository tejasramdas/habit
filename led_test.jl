using PyCall

function led_init()
    pushfirst!(PyVector(pyimport("sys")."path"), ".")
    return pyimport("led").LED()
end

led=led_init()

led.high()
sleep(1)
led.low()
