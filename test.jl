using GLMakie, VideoIO, Colors, ImageFiltering, Statistics


vid=VideoIO.load(file_name,target_format=VideoIO.AV_PIX_FMT_GRAY8)
size(vid)

vid_arr=Matrix{Gray}.(vid)

frame_num=Observable(1)
threshold_high=Observable(0.17)
threshold_low=Observable(0.03)

f=Figure()
ax=Axis(f[1,1])

tot_I=Int(floor(size(vid_arr[1])[1]/160))
tot_J=Int(floor(size(vid_arr[1])[1]/160))

# i=image!(ax,@lift(max.($threshold_low,min.($threshold_high,vid_arr[$frame_num]))),colorrange=[0,1])


i=image!(ax,@lift($threshold_low.<vid_arr[$frame_num].<$threshold_high),colorrange=[0,1])


contract=zeros(60,tot_I,tot_J)

manual_contract=zeros(60,tot_I,tot_J)


for i in 1:60
    for j in 1:tot_I
        for k in 1:tot_J
            prev=mean(threshold_low[].<vid_arr[i*2-1][(j-1)*160+1:j*160,(k-1)*160+1:k*160].<threshold_high[])
            aft=mean(threshold_low[].<vid_arr[i*2][(j-1)*160+1:j*160,(k-1)*160+1:k*160].<threshold_high[])
            if j==2 && k==2
                println("$i, $prev, $aft, $(aft/prev)")
            end
            contract[i,j,k]=(aft/prev)<0.8
            sleep(0.01)
        end
    end
end

p=Matrix{Any}(undef,tot_I,tot_J)
for i in p
    empty!(ax,i)
end
annot_arr=manual_contract
for i in 1:tot_I
    for j in 1:tot_J
        p[i,j]=poly!(ax,Point2f[((i-1)*160+1, (j-1)*160+1), (i*160, (j-1)*160+1), (i*160, j*160), ((i-1)*160+1, j*160)], color = @lift(RGBAf(100,0,0,(annot_arr[Int(ceil($frame_num/2)),i,j])*0.2)), strokecolor = :black, strokewidth = 1, )
    end
end

empty!(events(ax).mousebutton.listeners)
mouse_click = on(events(ax).mousebutton, priority=0) do event
    if event.button == Mouse.left && event.action == Mouse.press
        x, y = mouseposition(ax.scene)
        println(x,y)
        manual_contract[Int(ceil(frame_num[]/2)),Int(ceil(x/160)),Int(ceil(y/160))]=1-manual_contract[Int(ceil(frame_num[]/2)),Int(ceil(x/160)),Int(ceil(y/160))]
        notify(frame_num)
    end
end

empty!(events(ax).keyboardbutton.listeners)
on(events(f).keyboardbutton) do event
    if event.action == Keyboard.press
        if event.key == Keyboard.left 
            frame_num[]=(frame_num[]-3)%120+1
        end
        if event.key == Keyboard.right 
            frame_num[]=(frame_num[]+1)%120+1
        end
        if event.key == Keyboard.down 
            frame_num[]+=(2*(frame_num[]%2)-1)
        end
        println(frame_num[])
    end
end
