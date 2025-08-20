Set-ExecutionPolicy Unrestricted -Scope Process -Force;
git clone https://github.com/jamesstringerparsec/Easy-GPU-PV.git C:\Temp\Easy-GPU-PV;
cd C:\Temp\Easy-GPU-PV;
# Edit these values before running:
$isoPath = 'C:\ISOs\Win11_English_x64.iso';
$vmName = 'GPUVM';
$memory = '8GB'; $cores = 4; $disk = '40GB';
# Now run the installer script:
.\CopyFilesToVM.ps1 -SourcePath $isoPath -VMName $vmName -MemoryAmount $memory -CPUCores $cores -SizeBytes $disk -GPUName AUTO -GPUResourceAllocationPercentage 50 -Username GPUVM -Password 'CoolestPassword!' -Autologon 'true'

