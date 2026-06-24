using System;
using System.Runtime.InteropServices;

namespace CodexWindowsUpdate
{
    [ComImport]
    [Guid("8C3F1CDD-6173-4591-AEBD-A56A53CA77C1")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDownloadProgressChangedCallback
    {
        void Invoke([MarshalAs(UnmanagedType.Interface)] object downloadJob, [MarshalAs(UnmanagedType.Interface)] object callbackArgs);
    }

    [ComImport]
    [Guid("77254866-9F5B-4C8E-B9E2-C77A8530D64B")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDownloadCompletedCallback
    {
        void Invoke([MarshalAs(UnmanagedType.Interface)] object downloadJob, [MarshalAs(UnmanagedType.Interface)] object callbackArgs);
    }

    [ComImport]
    [Guid("E01402D5-F8DA-43BA-A012-38894BD048F1")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IInstallationProgressChangedCallback
    {
        void Invoke([MarshalAs(UnmanagedType.Interface)] object installationJob, [MarshalAs(UnmanagedType.Interface)] object callbackArgs);
    }

    [ComImport]
    [Guid("45F4F6F3-D602-4F98-9A8A-3EFA152AD2D3")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IInstallationCompletedCallback
    {
        void Invoke([MarshalAs(UnmanagedType.Interface)] object installationJob, [MarshalAs(UnmanagedType.Interface)] object callbackArgs);
    }

    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.None)]
    public sealed class WuaDownloadProgressCallback : IDownloadProgressChangedCallback
    {
        public void Invoke(object downloadJob, object callbackArgs) { }
    }

    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.None)]
    public sealed class WuaDownloadCompletedCallback : IDownloadCompletedCallback
    {
        public void Invoke(object downloadJob, object callbackArgs) { }
    }

    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.None)]
    public sealed class WuaInstallationProgressCallback : IInstallationProgressChangedCallback
    {
        public void Invoke(object installationJob, object callbackArgs) { }
    }

    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.None)]
    public sealed class WuaInstallationCompletedCallback : IInstallationCompletedCallback
    {
        public void Invoke(object installationJob, object callbackArgs) { }
    }
}
