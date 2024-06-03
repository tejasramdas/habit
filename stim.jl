#Julia functions to connect to PyBoard, access pin, and run basic strobe

using PyCall
using GLMakie

function stim_init()
    pushfirst!(PyVector(pyimport("sys")."path"), ".")
    return pyimport("stim").Stim()
end
function flash(stim=Nothing,t=0,p_w=0,period=0,offset=0)
    beg=time()
    curr_t=0
    try
        sleep(offset)
        while curr_t<(t-0.005)
            stim.high()
            sleep(p_w)
            stim.low()
            sleep(period-p_w)
            curr_t=time()-beg
        end
    catch e
        for i in 1:6
            stim.exec("pyb.LED(3).toggle()")
            sleep(0.1)
            stim.low()
        end
    end
   off()
end

