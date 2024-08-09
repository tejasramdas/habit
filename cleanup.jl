using DataFrames
##### IGNORE BELOW

println("DISK USAGE")
println()
println("Computer:")
println(run(`df -h /dev/nvme0n1p2`))
println()
println("SSD:")
println(run(`df -h /dev/sda1`))
println()

MASTER_FOLDERS=["/home/para","/media/para/T7_Tejas"]

println("Pick folder ($(MASTER_FOLDERS[1]) = 1, $(MASTER_FOLDERS[2]) = 2)")

#=MASTER_FOLDER=MASTER_FOLDERS[1]=#

MASTER_FOLDER=MASTER_FOLDERS[parse(Int,readline())]

datasets=DataFrame(dataset=sort(readdir("$MASTER_FOLDER/data")))
#=println(datasets)=#

println("$(size(datasets.dataset)[1]) folders")

for i in reverse(datasets.dataset)
    println()
    println(i)
    #=if !isfile("$MASTER_FOLDER/data/$(fold_name)/trial_$(trial_num)/dat2.bin")=#
    for j in ["dat.bin","dat2.bin", "dat.txt"]
        if isfile("$MASTER_FOLDER/data/$i/$j")
            siz=round(filesize("$MASTER_FOLDER/data/$i/$j")/1e9,digits=2)
            println("$j exists. Size: $siz GB")
        end
    end
    if i[end-2:end]=="del"
        println("Undo mark for deletion?")
        ans=readline()
        if ans=="y"
            run(`mv $MASTER_FOLDER/data/$i $MASTER_FOLDER/data/$(i[1:end-4])`)
            println("Undid mark")
        end
    else
        println("Mark for deletion?")
        ans=readline()
        if ans=="y"
            run(`mv $MASTER_FOLDER/data/$i $MASTER_FOLDER/data/$(i)_del`)
            println("Marked")
        end
    end
    println("Hit enter for next folder")
    readline()
end



#=start=2=#
#= # What is this chunk for? For reading all info about the dataset?=#
#=for i in (size(datasets.dataset)[1]-start+1):(size(datasets.dataset)[1])=#
#=    fold_name = datasets.dataset[i]=#
#=    try=#
#=        img_arr,img_info,notes=load_stack(MASTER_FOLDER*"/data/", fold_name);=#
#=        println(notes)=#
#=        println(fold_name)=#
#=        imshow(img_arr)=#
#=    catch e=#
#=        println(e)=#
#=        println("Problem with $i ($fold_name)")=#
#=    end=#
#=    x=readline()=#
#=    if x=="c"=#
#=        break=#
#=    end=#
#=    ImageView.closeall()=#
#=end=#

#=led_stat=map(x->["OFF","ON"][x],Int.(img_info.Stim).+1)=#
#=to_img=1=#
#=diff_arr=compute_diff(img_arr[:,:,1:2:end],fold_name;diff_step=1);=#

