using DataCurator
using Test
using Logging
using Random
using Images

@testset "DataCurator.jl" begin
    @testset "validate_dataset_hierarchy" begin
        c = global_logger()
        global_logger(NullLogger())
        root = mktempdir()
        pt = joinpath(root, "1", "Type 2", "Serie 14")
        mkpath(pt)
        a = zeros(3, 3, 3)
        f1 = joinpath(pt, "channel_1.tif")
        Images.save(f1, a)
        f2 = joinpath(pt, "channel_2.tif")
        Images.save(f2, a)
        isint = x -> ~isnothing(tryparse(Int, basename(x)))
        condition = x->false
        action = x-> @info x
        is3d = x-> length(size(Images.load(x)))==3
        is2d = x-> length(size(Images.load(x)))==3
        valid_channel = x -> occursin(r".*[1,2]\.tif", x)
        valid_cellnr = x->occursin(r"Serie\ [0-9]+", x)
        @test valid_cellnr("Serie 040")
        template = Dict()
        isint = x -> ~isnothing(tryparse(Int, splitpath(x)[end]))
        template[-1] = [(always, x-> quit_on_fail)]
        template[1] = [(x-> isdir(x), warn_on_fail)]
        template[2] = [(x->all_of(x, [isdir, isint]), warn_on_fail)]
        template[3] = [(x->isdir(x), warn_on_fail)]
        template[4] = [(x->all_of(x, [isdir, valid_cellnr]), warn_on_fail)]
        template[5] = [(x->all_of(x, [isfile, valid_channel, is3d]), warn_on_fail)]
        @test verify_template(root, template; act_on_success=false)==:proceed
        rm(root, force=true, recursive=true)
        global_logger(c)
    end

    @testset "shortcodes" begin
        rt = mktempdir()
        z = zeros(3,3,3)
        FN = joinpath(rt, "file.tif")
        Images.save(FN, z)
        @test isfile(FN)
        @test is_img(FN)
        @test is_3d_img(FN)
        @test ~ has_n_files(2, FN)
        has_n_files(rt, 2)
    end

    @testset "movelink" begin
        root = mktempdir()
        node = joinpath(root, "a", "b")
        mkpath(node)
        FL = joinpath(node, "Q.txt")
        touch(FL)
        # mkpath(node)
        newroot = mktempdir()
        # mkpath(newroot)
        newpath = new_path(root, node, newroot)
        np = copy_to(root, node, newroot)
        @test isdir(np)
        newpath = new_path(root, root, newroot)
        @test newpath == root
        rm(root, recursive=true, force=true)
    end

    @testset "movecopy" begin
        root = mktempdir()
        pt = joinpath(root, "1", "Type 2", "Serie 14")
        newroot = mktempdir()
        mkpath(pt)
        move_to(root, pt, newroot)
        qt = joinpath(newroot, "1", "Type 2", "Serie 14")
        @test ispath(qt)
        @test ~ispath(pt)
        rm(root, recursive=true)
        rm(newroot, recursive=true)
        root = mktempdir()
        pt = joinpath(root, "1", "Type 2", "Serie 14")
        fl = joinpath(pt, "test.txt")
        # touch(joinpath(pt, "test.txt"))
        newroot = mktempdir()
        mkpath(pt)
        touch(fl)
        qt = joinpath(newroot, "1", "Type 2", "Serie 14")
        nl = joinpath(qt, "test.txt")
        move_to(root, pt, newroot)
        @test ~isfile(fl)
        isfile(joinpath(qt, "test.txt"))
        @test ~ispath(pt)
        rm(root, recursive=true)
        rm(newroot, recursive=true)
        root = mktempdir()
        pt = joinpath(root, "1", "Type 2", "Serie 14")
        fl = joinpath(pt, "test.txt")
        # touch(joinpath(pt, "test.txt"))
        newroot = mktempdir()
        mkpath(pt)
        touch(fl)
        qt = joinpath(newroot, "1", "Type 2", "Serie 14")
        nl = joinpath(qt, "test.txt")
        copy_to(root, pt, newroot)
        @test isfile(fl)
        @test isfile(joinpath(qt, "test.txt"))
        @test ispath(pt)
        rm(root, recursive=true)
        rm(newroot, recursive=true)
    end


    @testset "relativecopy" begin
        root = mktempdir()
        pt = joinpath(root, "1", "Type 2", "Serie 14")
        fl = joinpath(pt, "test.txt")
        # touch(joinpath(pt, "test.txt"))
        newroot = mktempdir()
        mkpath(pt)
        touch(fl)
        qt = joinpath(newroot, "Serie 14")
        nl = joinpath(qt, "test.txt")
        copy_to(root, pt, newroot; keeprelative=false)
        @test ispath(qt)
        @test isfile(fl)
        # @test isfile(joinpath(newroot, "test.txt"))
        @test ispath(pt)
        rm(root, recursive=true)
        rm(newroot, recursive=true)
    end

    @testset "movelinkfile" begin
        root = mktempdir()
        node = joinpath(root, "a", "b")
        mkpath(node)
        node = joinpath(node, "Q.txt")
        touch(node)
        # mkpath(node)
        newroot = mktempdir()
        # mkpath(newroot)
        # newpath = new_path(root, node, newroot)
        np = copy_to(root, node, newroot)
        # @test isdir(np)
        # newpath = new_path(root, root, newroot)
        @test isfile(np)
        rm(root, recursive=true, force=true)
    end

    @testset "validate_dataset" begin
        c = global_logger()
        global_logger(NullLogger())
        root = mktempdir()
        pt = joinpath(root, "1", "Type 2", "Serie 14")
        mkpath(pt)
        a = zeros(3, 3, 3)
        f1 = joinpath(pt, "channel_1.tif")
        Images.save(f1, a)
        f2 = joinpath(pt, "channel_2.tif")
        Images.save(f2, a)
        isint = x -> ~isnothing(tryparse(Int, basename(x)))
        condition = x->false
        action = x-> @info x
        is3d = x-> length(size(Images.load(x)))==3
        is2d = x-> length(size(Images.load(x)))==3
        valid_channel = x -> occursin(r".*[1,2]\.tif", x)
        valid_cellnr = x->occursin(r"Serie\ [0-9]+", x)
        @test valid_cellnr("Serie 040")
        Q = make_counter()#ParallelCounter(zeros(Int64, Base.Threads.nthreads()))
        countsize = x -> increment_counter(Q; inc=filesize(x))
        template = [(isfile, countsize)]
        verify_template(root, template; act_on_success=true)
        @test sum(Q.data) == 1648
        Q = make_counter(true)
        verify_template(root, template; act_on_success=true, parallel_policy="parallel")
        @test   sum(Q.data) == 1648
        rm(root, force=true, recursive=true)
        global_logger(c)
    end

#
# Q = ParallelCounter(zeros(Int64, Base.Threads.nthreads()))
# countsize = x -> _parallel_increment(Q; inc=filesize(x))
# template = [(isfile, countsize)]
# verify_template(root, template; act_on_success=true)
# sum(Q.data)

    ### Count triggers
    ### Count filesizes
    ###

    # @testset "counter" begin
    #     QT = ParallelCounter(zeros(Int64, Base.Threads.nthreads()))
    #     # Count file sizes
    # end

    @testset "transformer" begin
        c = global_logger()
        global_logger(NullLogger())
        root = mktempdir()
        N = 1
        mkpath(joinpath(root, ["$i" for i in 1:N]...))
        for i in 1:N
                touch(joinpath(root, ["$i" for i in 1:i]..., " $i .txt"))
        end
        condition = x -> ~contains(x, ' ')
        no_space = x -> replace(x, ' ' => '_')
        action = x -> transform_inplace(x, no_space)
        has_whitespace = condition
        space_to_ = action
        @test transform_template(root, [(has_whitespace, space_to_)]) == :proceed
        verify_template(root, [(has_whitespace, space_to_)]) == :proceed
        rm(root, recursive=true, force=true)
        global_logger(c)
    end

    @testset "transform" begin
        c = global_logger()
        global_logger(NullLogger())
        root = mktempdir()
        mkpath(joinpath(root, "a"))
        pt = joinpath(root, "a")
        @test isdir(pt)
        file = joinpath(root, "a", "a.txt")
        touch(file)
        @test isfile(file)
        nf = transform_copy(file, x->x)
        @test isfile(nf)
        up = x -> uppercase(x)
        nf = transform_inplace(file, up)
        @test ~isfile(file)
        @test isfile(nf)
        nd = transform_copy(pt, up)
        @test isdir(nd)
        @test isdir(pt)
        rm(root, recursive=true, force=true)
        root = mktempdir()
        PT = joinpath(root, "a")
        mkpath(PT)
        nf = transform_inplace(PT, up)
        @test isdir(nf)
        @test ~isdir(PT)
        rm(root, recursive=true, force=true)
        global_logger(c)
    end

    @testset "traversal" begin
        c = global_logger()
        global_logger(NullLogger())
        root = mktempdir()
        # root = "/dev/shm/test"
        C = [11, 21, 41]
        for (j,N) in enumerate([5, 10, 20])
            mkpath(joinpath(root, ["$i" for i in 1:N]...))
            for i in 1:N
                touch(joinpath(root, ["$i" for i in 1:i]..., "$i.txt"))
            end
            visitor = x -> ~isnothin(tryparse(Int, basename(x)))
            vts = x -> @debug x
            topdown(root, expand_filesystem, vts)
            bottomup(root, expand_filesystem, vts)
            i = Threads.Atomic{Int}(0);
            visitor = x -> Threads.atomic_add!(i, 1)
            topdown(root, expand_filesystem, visitor)
            @test i[] ==  C[j]
            i = Threads.Atomic{Int}(0);
            bottomup(root, expand_filesystem, visitor)
            @test i[] == C[j]
            rm(root, force=true, recursive=true)
        end
        global_logger(c)

    end

    @testset "exittest" begin
        c = global_logger()
        global_logger(NullLogger())
        root = mktempdir()
        # root = "/dev/shm/test"
        C = [41, 100]
        for (j,N) in enumerate([20, 100])
            mkpath(joinpath(root, ["$i" for i in 1:N]...))
            for i in 1:N
                touch(joinpath(root, ["$i" for i in 1:i]..., "$i.txt"))
            end
            i = Threads.Atomic{Int}(0);
            visitor = x -> begin Threads.atomic_add!(i, 1); (rand() > 0.5) ? (return :quit) : (return :proceed); end
            topdown(root, expand_filesystem, visitor)
            @test i[] <  C[j]
            i = Threads.Atomic{Int}(0);
            bottomup(root, expand_filesystem, visitor)
            @test i[] < C[j]
            rm(root, force=true, recursive=true)
        end
        global_logger(c)

    end


    @testset "fuzz" begin
        # warnquit = x -> begin @warn x; return :quit; end
        N = 100
        c = global_logger()
        global_logger(NullLogger())
        import Random
        Random.seed!(42)
        for i in 1:N
            root = mktempdir()
            # for (j,N) in enumerate([N])
            M = rand(10:20)
            mkpath(joinpath(root, ["$i" for i in 1:M]...))
            for i in 1:M
                touch(joinpath(root, ["$i" for i in 1:i]..., "$i.txt"))
            end
            # i = Threads.Atomic{Int}(0);
            q=verify_template(root, [(x->false, quit_on_fail)])
            @test q == :quit
            q=verify_template(root, [(x->false, warn_on_fail)])
            @test q == :proceed
            rm(root, force=true, recursive=true)
        end
        global_logger(c)

        # end
    end

    @testset "hierarchical" begin
        N = 500
        c = global_logger()
        global_logger(NullLogger())
        Random.seed!(42)
        for i in 1:N
            root = mktempdir()
            # for (j,N) in enumerate([N])
            M = rand(10:10)
            mkpath(joinpath(root, ["$i" for i in 1:M]...))
            for i in 1:M
                touch(joinpath(root, ["$i" for i in 1:i]..., "$i.txt"))
            end
            # i = Threads.Atomic{Int}(0);
            q=verify_template(root, [(x->false, quit_on_fail)])
            @test q == :quit
            q=verify_template(root, [(x->false, warn_on_fail)])
            @test q == :proceed
            template = [(x->false, warn_on_fail)]
            templater = Dict([(-1, template), (1, template)])
            z=verify_template(root, templater; traversalpolicy=topdown)
            @test z == :proceed
            z=verify_template(root, template; traversalpolicy=topdown)
            @test z == :proceed
            templater = Dict([(1, template)])
            z=verify_template(root, templater; traversalpolicy=topdown)
            @test z == :proceed
            templater = Dict([(i, template) for i in 1:M])
            z=verify_template(root, templater; traversalpolicy=topdown)
            @test z == :proceed
            z=verify_template(root, templater; traversalpolicy=topdown, parallel_policy="parallel")
            @test z == :proceed
            rm(root, force=true, recursive=true)
        end
        global_logger(c)
    end


end
