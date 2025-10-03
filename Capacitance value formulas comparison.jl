using DataFrames
using CSV
using NativeFileDialog
using NumericalIntegration
using PrettyTables
using Statistics

function import_files()
    println("pick either a charge or discharge file")
    file_CD=pick_file()
    df=CSV.read(file_CD,DataFrame)

    file_name=basename(file_CD)

    Set_current=df."WE(1).Current (A)"
    Time=df."Corrected time (s)"
    Potential=df."WE(1).Potential (V)"
    
    Total_time=maximum(Time)
    Integral_potential=integrate(Time,Potential)
    Current_average=mean(Set_current)
    Potential_max=maximum(Potential)

    return Total_time,Integral_potential,
    Current_average,Potential_max,file_name
end

function Capacitance_calculation()
    Total_time,Integral_potential,Current_average,
    Potential_max,file_name=import_files()

    C_classic=(abs(Current_average)*Total_time)/Potential_max
    C_integral=(2*abs(Current_average)*Integral_potential)/(Potential_max^2)

    C_difference=abs(C_classic-C_integral)
    C_ratio=C_classic/C_integral

    header=(["File name","C_classic","C_integral",
    "C_difference","C_ratio"])

    data=([file_name C_classic C_integral C_difference C_ratio])
    
    pretty_table(data;header)

    println("pick a folder where to save the table")
    save_folder=pick_folder()
    
    open(joinpath(save_folder,"$file_name-table.csv"), write=true) do io
        pretty_table(io,data;header)
    end

end

Capacitance_calculation()

