using PyCall
using GLMakie


function led_init()
    pushfirst!(PyVector(pyimport("sys")."path"), ".")
    return pyimport("led").LED()
end


function flash_led_py(led,t=0,p_w=0,period=0;offset=0)
    led.flash(t,period,offset,p_w)
end

function create_screen()
    f=Figure(backgroundcolor=:black)
    ax=GLMakie.Axis(f[1,1],backgroundcolor=:black)
    hidedecorations!(ax)
    hidespines!(ax)
    xlims!(ax,0,1)
    ylims!(ax,0,1)
    display(f)
    return f,ax
end

function rect(ax,color)
    return poly!(ax,Point2f[(0, 0), (1, 0), (1, 1), (0, 1)], color = color, strokewidth = 0)
end

function flash(t=0,p_w=0,period=0,led_mode=true;ax=Nothing,color=:black,led=Nothing,offset=0)
    if led_mode
        on=()->led.high()
        off=()->led.low()
    else
        on=()->rect(ax,color)
        off=()->empty!(ax)
    end
    beg=time()
    curr_t=0
    curr_stat=false
    while curr_t<(t-0.001)
        curr_t=time()-beg
        if curr_t>offset
            if (curr_t-offset)%period<p_w && !curr_stat 
                curr_stat=true
                on()
            elseif (curr_t-offset)%period>p_w && curr_stat 
                curr_stat=false
                off()
            else
            end
        end
        sleep(0.001)
        curr_t=time()-beg
    end
    off()
end

