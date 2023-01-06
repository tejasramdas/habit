using Images, GLMakie, ProgressBars, FFTW, JLD


function load_sep()
    folder="test2";
    i=1;
    img_name(i)="$folder/img_$(lpad(i,5,"0")).png";

    img_arr=[];

    for i in tqdm(1:50)
        push!(img_arr,Images.load(img_name(i)));
    end
    return img_arr
end

function load_stack()
    folder="frames/2023_01_05_13_11_05/"
    test=JLD.load(folder*"data.jld")["frames"]
end

function transform(img_arr)
    for i in tqdm(1:size(img_arr)[1])
        img_arr[i]=rotr90(img_arr[i])[end:-1:1,:]
    end
    return img_arr
end


img_arr=load_stack()

frame_num=Observable(1)

f=Figure(res=(1000,500)); ax=GLMakie.Axis(f[1,1]); ax2=GLMakie.Axis(f[1,2]); 

image!(ax,@lift(img_arr[$frame_num]))

screen=display(f)
resize!(screen, 1000,500)

diff_arr=diff(img_arr[1:2:200]);

on(events(f).keyboardbutton) do event
    if event.action in (Keyboard.press, Keyboard.repeat)
        if event.key == Keyboard.enter
            frame_num[]=(frame_num[]%1995)+1
             
        end
    end
end

image!(ax2,@lift(diff_arr[$frame_num]))

image!(ax2,@lift(bandpass(diff_arr[$frame_num])))


function bandpass(img,l=1,h=size(img)[1])
    fft_img = fft(Float32.(img))
    fft_img[1:l,1:l] .= 0
    fft_img[h:end,h:end] .= 0
    ifft_img = abs.(ifft(fft_img))
end

