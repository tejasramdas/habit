using Images, GLMakie, ProgressBars, FFTW, HDF5


function load_stack(fold_name=readdir("/ssd")[end])
    file_loc="/ssd/"*fold_name*"/dat.h5"
    file=h5open(file_loc)
    dat=read(file)
    temp=[]
    for i in keys(dat)
        push!(temp,dat[i])
    end
    close(file)
    println("Loaded $file_loc...")
    return cat(temp...,dims=3)
end

function transform(img_arr)
    for i in tqdm(1:size(img_arr)[1])
        img_arr[i]=rotr90(img_arr[i])[end:-1:1,:]
    end
    return img_arr
end

img_arr=zeros(UInt8,2048,2048,20)

diff_arr=diff(Float16.(img_arr)/Float16(255.0),dims=3);

frame_num=Observable(1)
to_img=Observable(1)
threshold=Observable(0.0)

function make_plot()
    f=Figure(res=(1000,1000)); 
    ax1=GLMakie.Axis(f[1,1]); 
    ax2=GLMakie.Axis(f[1,2]); 
    # ax3=GLMakie.Axis(f[2,:]);
    title = Label(f[0, :], @lift("Frame: $($to_img*$frame_num)"), fontsize = 20)
    img_plot=image!(ax1,@lift(reinterpret(N0f8,img_arr[:,:,$to_img*$frame_num])),interpolate=false)
    diff_plot=image!(ax2,@lift(max.($threshold,diff_arr[:,:,$frame_num]).-$threshold),interpolate=false)
    # diff_histo=hist!(ax3,@lift(diff_arr[1:4:end,1:4:end,$frame_num][:]),bins=collect(-1.0:0.1:1.0))
    listen=on(events(f).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat)
            if event.key == Keyboard.enter
                frame_num[]=(frame_num[]%(size(diff_arr)[end]))+1
            elseif event.key == Keyboard.space
                frame_num[]=((frame_num[]+size(diff_arr)[end]-2)%(size(diff_arr)[end]))+1
            end
        end
    end
    return f,ax1,ax2,diff_plot,listen
end

function show_plot(f=plt[1])
    screen=display(f)
    resize!(screen, 1000,500)
    # hidedecorations!(ax1)
    # hidedecorations!(ax2)
end

function zoom(x_l=0,y_l=0,x_h=x_l+100,y_h=y_l+100;plt=plt)
    ax1=plt[2]
    ax2=plt[3]
    xlims!(ax1,x_l,x_h)
    xlims!(ax2,x_l,x_h)
    ylims!(ax1,y_l,y_h)
    ylims!(ax2,y_l,y_h)
end

function res(plt=plt)
    zoom(0,0,2048,2048,plt=plt)
end

function bandpass(img,l=1,h=size(img)[1])
    fft_img = fft(Float16.(img))
    fft_img[1:l,1:l] .= 0
    fft_img[h:end,h:end] .= 0
    ifft_img = abs.(ifft(fft_img))
end

# filter_plot=image!(ax,@lift(bandpass(reinterpret(N0f8,img_arr[:,:,$frame_num]))))
#


#################


img_arr=load_stack();

to_img[]=4

diff_arr=diff(Float16.(img_arr[:,:,1:to_img[]:end])/Float16(255.0),dims=3);

plt=make_plot()

show_plot()

f_s=22
b_x=1930
b_y=1125
hist_x=Int[]
hist_y=Int[]
for i in f_s:f_s+10
    blo=blob_LoG(PaddedView(0,diff_arr,(2500,2048,49))[b_x:b_x+100,b_y:b_y+100,i],[10,20,30])
    print(size(blo)[1],", ")
    scat=map(x->(x.location[1],x.location[2]),blo)[findmax(map(x->x.amplitude,blo))[2]]
    push!(hist_x,b_x+scat[1])
    push!(hist_y,b_y+scat[2])
    b_x+=scat[1]-50
    b_y+=scat[2]-50
end

image(@lift(diff_arr[1840:2040,1075:1275,$fol]))
lines!(hist_x.-1840,hist_y.-1075)
