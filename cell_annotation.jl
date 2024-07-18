using GLMakie, VideoIO, Colors, ImageFiltering, Statistics, DataFrames, RollingFunctions, HDF5

#Change filename to path

MASTER_FOLDER="/home/para"

datasets=DataFrame(dataset=sort(readdir("$MASTER_FOLDER/data")))
println(datasets)

fold_name=datasets.dataset[3]

vid=VideoIO.load("$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled.mp4",target_format=VideoIO.AV_PIX_FMT_GRAY8)
size(vid)

vid_arr=Matrix{Gray}.(vid)

frame_num=Observable(1)
threshold_high=Observable(0.17)
threshold_low=Observable(0.03)

f=Figure(size=(512,512))
ax=Axis(f[2:10,1:9])
lab=Label(f[1,:],@lift("Stimulus $($Int(ceil($frame_num/2)))"))

tot_I=Int(floor(size(vid_arr[1])[1]/160))
tot_J=Int(floor(size(vid_arr[1])[1]/160))

# i=image!(ax,@lift(max.($threshold_low,min.($threshold_high,vid_arr[$frame_num]))),colorrange=[0,1])


i=image!(ax,@lift($threshold_low.<vid_arr[$frame_num].<$threshold_high),colorrange=[0,1])

i=image!(ax,@lift(vid_arr[$frame_num].*3),colorrange=[0,1])

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

empty!(events(ax).mousebutton.listeners)
mouse_click = on(events(ax).mousebutton, priority=0) do event
    if event.button == Mouse.left && event.action == Mouse.press
        x, y = mouseposition(ax.scene)
        if 0<x<size(vid[1])[1] && 0<y<size(vid[1])[2]
            manual_contract[Int(ceil(frame_num[]/2)),Int(ceil(x/160)),Int(ceil(y/160))]=1-manual_contract[Int(ceil(frame_num[]/2)),Int(ceil(x/160)),Int(ceil(y/160))]
            notify(frame_num)
        end
    end
end

function lim(n)
    return min(120,max(1,n))
end

empty!(events(ax).keyboardbutton.listeners)
on(events(f).keyboardbutton) do event
    if event.action == Keyboard.press
        if event.key == Keyboard.left 
            frame_num[]=lim(frame_num[]-2)
        end
        if event.key == Keyboard.right 
            frame_num[]=lim(frame_num[]+2)
        end
        if event.key == Keyboard.down 
            frame_num[]+=(2*(frame_num[]%2)-1)
        end
    end
end

t=Threads.@async begin
    while true
        frame_num[]+=(2*(frame_num[]%2)-1)
        sleep(0.5)
    end
end

schedule(t,InterruptException();error=true)


annot_arr=contract

for i in p
    empty!(ax,i)
end

for i in 1:tot_I
    for j in 1:tot_J
        p[i,j]=poly!(ax,Point2f[((i-1)*160+1, (j-1)*160+1), (i*160, (j-1)*160+1), (i*160, j*160), ((i-1)*160+1, j*160)], color = @lift(RGBAf(100,0,0,(annot_arr[Int(ceil($frame_num/2)),i,j])*0.2)), strokecolor = :black, strokewidth = 1, )
    end
end


schedule(t,InterruptException();error=true)
fps = 2
record(f, "$MASTER_FOLDER/data/$fold_name/$(fold_name)_auto_annotation.mp4"; framerate = fps) do io
    frame_num[]=1
    recordframe!(io)
    for i = 1:119
        frame_num[]+=1
        sleep(0.01)
        recordframe!(io)
    end
end

f_dat=Figure()
ax=Axis(f_dat[1:3,1:3],xlabel="Stimulus number",ylabel="Contraction probability")
sing=rolling.(mean,[reshape(contract,(60,:))[:,i] for i in 1:16],5)
for i in 1:5
    lines!(ax,sing[i+4][1:end],label="Cell $(i+4)")
end
lines!(ax,mean(hcat(sing...),dims=2)[1:end,1],linewidth=3,color=:black,label="Mean (16 cells)")
l=Legend(f_dat[2,4],ax)
save("$MASTER_FOLDER/data/$fold_name/$(fold_name)_auto_annotation_curve.png", f_dat)

contract_save=h5open("$MASTER_FOLDER/data/$fold_name/$(fold_name)_contractions.h5")
contract_save["auto"]=contract
contract_save["
