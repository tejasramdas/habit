using GLMakie

fig=Figure()
ax=Axis(fig[1,1])

frame_num=Observable(1)
switcher=Observable(false)
toggle=Observable(false)

tiled=...

Threads.@async begin
    while true
        if switcher[]
            toggle[] = 1-toggle[]
        end
    end
end


image!(tiled,ax)
