using Godot;
using System;
using System.IO.Hashing;

/// <summary>
/// Exposes a high-performance, deterministic, hashing function not otherwise directly available to GDScript.
/// </summary>
public partial class Hasher : GodotObject
{
    /// <summary>
    /// Provides access to high-performance hashing functions.
    /// </summary>
    public static String Hash(byte[] data)
    {
        byte[] hashValue = XxHash3.Hash(data);
        return BitConverter.ToString(hashValue).Replace("-", "");
    }
}
