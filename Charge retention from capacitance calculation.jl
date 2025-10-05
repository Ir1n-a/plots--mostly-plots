using DataFrames
using CSV
using Statistics
using GLMakie
using NumericalIntegration
using NativeFileDialog

function import_folders()
    println("import the charge file")
    charge_file=pick_file()

    filename_charge=basename(charge_file)
    df_charge=CSV.read(charge_file,DataFrame)

    Time_charge=df_charge."Corrected time (s)"
    Potential_charge=df_charge."WE(1).Potential (V)"
    Ch_int=integrate(Time_charge,Potential_charge)

    println("import discharge file")
    discharge_file=pick_file()

    filename_discharge=basename(discharge_file)
    df_discharge=CSV.read(discharge_file,DataFrame)

    Time_discharge=df_discharge."Corrected time (s)"
    Potential_discharge=df_discharge."WE(1).Potential (V)"
    Dis_int=integrate(Time_discharge,Potential_discharge)

    return df_charge,df_discharge,filename_charge,
    filename_discharge,Ch_int,Dis_int
end

function cd_capacitance_calculation(n)
    C_ratio=[]
    C_charge_v=[]
    C_discharge_v=[]
    iteration=[]

    for i in 1:n 
        df_charge,df_discharge,filename_charge,
        filename_discharge,Ch_int,Dis_int=import_folders()

        Charge_current=mean(df_charge."WE(1).Current (A)")
        Charge_potential=maximum(df_charge."WE(1).Potential (V)")
        Charge_time=maximum(df_charge."Corrected time (s)")
    
        Discharge_current=mean(df_discharge."WE(1).Current (A)")
        Discharge_potential=maximum(df_discharge."WE(1).Potential (V)")
        Discharge_time=maximum(df_discharge."Corrected time (s)")

        C_charge=(2*abs(Charge_current)*Ch_int)/
        (Charge_potential^2)
        C_discharge=(2*abs(Discharge_current)*Dis_int)/
        (Discharge_potential^2)

        push!(C_charge_v,C_charge)
        push!(C_discharge_v,C_discharge)
        push!(C_ratio,C_charge/C_discharge)
        push!(iteration,i)
    end

    @show C_charge_v 
    @show C_discharge_v
    @show C_ratio 
end
#each charge file needs to have a corresponding discharge file,
#so how do I do that?

cd_capacitance_calculation(2)