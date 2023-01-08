using PyCall


function led_init()
    pushfirst!(PyVector(pyimport("sys")."path"), ".")
    return pyimport("led").LED()
end


function flash_led(led,t=0,p_w=0,period=0;offset=0)
    beg=time()
    curr_t=0
    x=[]
    while curr_t<(t-0.001)
        curr_t=time()-beg
        if curr_t>offset
            if (curr_t-offset)%period<p_w
                push!(x,1)
                led.high()
            else
                push!(x,0)
                led.low()
            end
        end
        curr_t=time()-beg
    end
    led.low()
    return x
end

