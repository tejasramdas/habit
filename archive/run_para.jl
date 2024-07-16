include("proc.jl")

img_arr=zeros(UInt8,2048,2048,20)
diff_arr=diff(Float16.(img_arr)/Float16(255.0),dims=3);

frame_num=Observable(1)
to_img=1
threshold=Observable(0.03)
p_x=Observable(1)
p_y=Observable(1)

datasets=DataFrame(dataset=readdir("/home/para/data"))

fold_name = datasets.dataset[14]

img_arr,img_info,notes=load_stack(fold_name);
print(notes)

led_stat=map(x->["OFF","ON"][x],Int.(img_info.LED).+1)

to_img=1

diff_arr=compute_diff(img_arr[:,:,1:2:end],fold_name;diff_step=1);

win_width=2048
plt=make_plot(img_arr,diff_arr,img_info.Cam,led_stat,win_width=win_width)
listen=frameshift(plt[1],frame_num,size(diff_arr)[end],p_x)
show_plot()

print("Enter x: ")
s_x=parse(Int,readline())

print("Enter y: ")
s_y=parse(Int,readline())

empty!(plt[1])
win_width=80
plt=make_plot(img_arr,diff_arr,img_info.Cam, led_stat,win_width=win_width)
listen=frameshift(plt[1],frame_num,size(diff_arr)[end],p_x)

show_plot()

GC.gc()

x,y,p,s=track(diff_arr[1:1000],s_x,s_y,win_width=80,plot_path=false,plt=Nothing,blob_s=[5,10,20],thresh=0.03);

record(plt[1], "/home/para/data/$fold_name/out_stim.mp4", 1:2:2000; framerate = 20) do i
    frame_num[]=i
    print(i)
    recto.color= led_stat[i]=="OFF" ? :black : :blue
    notify(p_x)
end

boxp = Point2f[[1800, 1800], [2000, 1800], [2000, 2000], [1800, 2000]]
recto=poly!(plt[2],boxp,color=:black)

