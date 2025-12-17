//! JikJoken C FFI wrapper for TikToken
//!
//! This library provides C-compatible FFI bindings to OpenAI's TikToken tokenizer
//! for use with Julia via ccall.

use std::collections::HashSet;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_uint};
use std::ptr;
use std::slice;

use rustc_hash::FxHashMap as HashMap;

// Vendored tiktoken core (modified for public API)
mod tiktoken_core;
use tiktoken_core::{CoreBPE, Rank};

/// Error codes for C FFI
#[repr(C)]
pub enum JikJokenError {
    Success = 0,
    NullPointer = 1,
    InvalidUtf8 = 2,
    InvalidToken = 3,
    EncodeError = 4,
    DecodeError = 5,
    AllocationError = 6,
}

/// Opaque handle to a CoreBPE encoder
pub struct JikJokenEncoding {
    inner: CoreBPE,
}

/// Result structure for encode operations
#[repr(C)]
pub struct JikJokenTokens {
    tokens: *mut Rank,
    length: usize,
}

/// Free a JikJokenTokens structure
#[no_mangle]
pub unsafe extern "C" fn jikjoken_tokens_free(tokens: *mut JikJokenTokens) {
    if !tokens.is_null() {
        let tokens = Box::from_raw(tokens);
        if !tokens.tokens.is_null() {
            let _ = Vec::from_raw_parts(tokens.tokens, tokens.length, tokens.length);
        }
    }
}

/// Create a new CoreBPE encoding from raw data
///
/// # Safety
/// - `encoder_keys` and `encoder_values` must be valid pointers to arrays of length `encoder_len`
/// - `special_keys` and `special_values` must be valid pointers to arrays of length `special_len`
/// - `pattern` must be a valid null-terminated UTF-8 string
/// - All string pointers must remain valid for the duration of this call
#[no_mangle]
pub unsafe extern "C" fn jikjoken_encoding_new(
    encoder_keys: *const *const u8,
    encoder_key_lens: *const usize,
    encoder_values: *const Rank,
    encoder_len: usize,
    special_keys: *const *const c_char,
    special_values: *const Rank,
    special_len: usize,
    pattern: *const c_char,
    out_handle: *mut *mut JikJokenEncoding,
) -> c_int {
    if encoder_keys.is_null()
        || encoder_key_lens.is_null()
        || encoder_values.is_null()
        || special_keys.is_null()
        || special_values.is_null()
        || pattern.is_null()
        || out_handle.is_null()
    {
        return JikJokenError::NullPointer as c_int;
    }

    // Build encoder HashMap
    let encoder_keys_slice = slice::from_raw_parts(encoder_keys, encoder_len);
    let encoder_key_lens_slice = slice::from_raw_parts(encoder_key_lens, encoder_len);
    let encoder_values_slice = slice::from_raw_parts(encoder_values, encoder_len);

    let mut encoder: HashMap<Vec<u8>, Rank> = HashMap::default();
    for i in 0..encoder_len {
        let key_ptr = encoder_keys_slice[i];
        let key_len = encoder_key_lens_slice[i];
        let key = slice::from_raw_parts(key_ptr, key_len).to_vec();
        encoder.insert(key, encoder_values_slice[i]);
    }

    // Build special tokens HashMap
    let special_keys_slice = slice::from_raw_parts(special_keys, special_len);
    let special_values_slice = slice::from_raw_parts(special_values, special_len);

    let mut special_tokens: HashMap<String, Rank> = HashMap::default();
    for i in 0..special_len {
        let key_cstr = match CStr::from_ptr(special_keys_slice[i]).to_str() {
            Ok(s) => s,
            Err(_) => return JikJokenError::InvalidUtf8 as c_int,
        };
        special_tokens.insert(key_cstr.to_string(), special_values_slice[i]);
    }

    // Get pattern string
    let pattern_str = match CStr::from_ptr(pattern).to_str() {
        Ok(s) => s,
        Err(_) => return JikJokenError::InvalidUtf8 as c_int,
    };

    // Create CoreBPE
    match CoreBPE::new_internal(encoder, special_tokens, pattern_str) {
        Ok(core) => {
            let encoding = Box::new(JikJokenEncoding { inner: core });
            *out_handle = Box::into_raw(encoding);
            JikJokenError::Success as c_int
        }
        Err(_) => JikJokenError::EncodeError as c_int,
    }
}

/// Free a JikJokenEncoding handle
#[no_mangle]
pub unsafe extern "C" fn jikjoken_encoding_free(handle: *mut JikJokenEncoding) {
    if !handle.is_null() {
        let _ = Box::from_raw(handle);
    }
}

/// Encode text to tokens (ordinary encoding, no special tokens)
///
/// # Safety
/// - `handle` must be a valid JikJokenEncoding pointer
/// - `text` must be a valid null-terminated UTF-8 string
/// - `out_tokens` must be a valid pointer to receive the result
#[no_mangle]
pub unsafe extern "C" fn jikjoken_encode_ordinary(
    handle: *const JikJokenEncoding,
    text: *const c_char,
    out_tokens: *mut *mut JikJokenTokens,
) -> c_int {
    if handle.is_null() || text.is_null() || out_tokens.is_null() {
        return JikJokenError::NullPointer as c_int;
    }

    let encoding = &(*handle).inner;
    let text_str = match CStr::from_ptr(text).to_str() {
        Ok(s) => s,
        Err(_) => return JikJokenError::InvalidUtf8 as c_int,
    };

    let mut tokens = encoding.encode_ordinary(text_str);
    let length = tokens.len();
    let tokens_ptr = tokens.as_mut_ptr();
    std::mem::forget(tokens);

    let result = Box::new(JikJokenTokens {
        tokens: tokens_ptr,
        length,
    });
    *out_tokens = Box::into_raw(result);

    JikJokenError::Success as c_int
}

/// Encode text to tokens with special token control
///
/// # Safety
/// - `handle` must be a valid JikJokenEncoding pointer
/// - `text` must be a valid null-terminated UTF-8 string
/// - `allowed_special` must be valid null-terminated UTF-8 strings or null pointers
#[no_mangle]
pub unsafe extern "C" fn jikjoken_encode(
    handle: *const JikJokenEncoding,
    text: *const c_char,
    allowed_special: *const *const c_char,
    allowed_special_len: usize,
    out_tokens: *mut *mut JikJokenTokens,
) -> c_int {
    if handle.is_null() || text.is_null() || out_tokens.is_null() {
        return JikJokenError::NullPointer as c_int;
    }

    let encoding = &(*handle).inner;
    let text_str = match CStr::from_ptr(text).to_str() {
        Ok(s) => s,
        Err(_) => return JikJokenError::InvalidUtf8 as c_int,
    };

    // Build allowed special tokens set
    let mut allowed_set = HashSet::new();
    if !allowed_special.is_null() && allowed_special_len > 0 {
        let allowed_slice = slice::from_raw_parts(allowed_special, allowed_special_len);
        for i in 0..allowed_special_len {
            let special_cstr = match CStr::from_ptr(allowed_slice[i]).to_str() {
                Ok(s) => s,
                Err(_) => return JikJokenError::InvalidUtf8 as c_int,
            };
            allowed_set.insert(special_cstr);
        }
    }

    // Encode
    let result = match encoding.encode(text_str, &allowed_set) {
        Ok((mut tokens, _)) => {
            let length = tokens.len();
            let tokens_ptr = tokens.as_mut_ptr();
            std::mem::forget(tokens);

            let result = Box::new(JikJokenTokens {
                tokens: tokens_ptr,
                length,
            });
            *out_tokens = Box::into_raw(result);
            JikJokenError::Success as c_int
        }
        Err(_) => JikJokenError::EncodeError as c_int,
    };

    result
}

/// Decode tokens to bytes
///
/// # Safety
/// - `handle` must be a valid JikJokenEncoding pointer
/// - `tokens` must be a valid pointer to an array of `length` elements
/// - `out_bytes` and `out_length` must be valid pointers
#[no_mangle]
pub unsafe extern "C" fn jikjoken_decode_bytes(
    handle: *const JikJokenEncoding,
    tokens: *const Rank,
    length: usize,
    out_bytes: *mut *mut u8,
    out_length: *mut usize,
) -> c_int {
    if handle.is_null() || tokens.is_null() || out_bytes.is_null() || out_length.is_null() {
        return JikJokenError::NullPointer as c_int;
    }

    let encoding = &(*handle).inner;
    let tokens_slice = slice::from_raw_parts(tokens, length);

    match encoding.decode_bytes(tokens_slice) {
        Ok(mut bytes) => {
            let bytes_len = bytes.len();
            let bytes_ptr = bytes.as_mut_ptr();
            std::mem::forget(bytes);

            *out_bytes = bytes_ptr;
            *out_length = bytes_len;
            JikJokenError::Success as c_int
        }
        Err(_) => JikJokenError::DecodeError as c_int,
    }
}

/// Free a byte array returned by jikjoken_decode_bytes
#[no_mangle]
pub unsafe extern "C" fn jikjoken_bytes_free(bytes: *mut u8, length: usize) {
    if !bytes.is_null() {
        let _ = Vec::from_raw_parts(bytes, length, length);
    }
}

/// Get the special tokens set
///
/// # Safety
/// - `handle` must be a valid JikJokenEncoding pointer
/// - `out_tokens` and `out_length` must be valid pointers
#[no_mangle]
pub unsafe extern "C" fn jikjoken_special_tokens(
    handle: *const JikJokenEncoding,
    out_tokens: *mut *mut *mut c_char,
    out_length: *mut usize,
) -> c_int {
    if handle.is_null() || out_tokens.is_null() || out_length.is_null() {
        return JikJokenError::NullPointer as c_int;
    }

    let encoding = &(*handle).inner;
    let special_tokens = encoding.special_tokens();

    let mut token_ptrs: Vec<*mut c_char> = Vec::with_capacity(special_tokens.len());
    for token in special_tokens {
        match CString::new(token) {
            Ok(cstring) => token_ptrs.push(cstring.into_raw()),
            Err(_) => {
                // Clean up already allocated strings
                for ptr in token_ptrs {
                    let _ = CString::from_raw(ptr);
                }
                return JikJokenError::InvalidUtf8 as c_int;
            }
        }
    }

    let length = token_ptrs.len();
    let tokens_ptr = token_ptrs.as_mut_ptr();
    std::mem::forget(token_ptrs);

    *out_tokens = tokens_ptr;
    *out_length = length;
    JikJokenError::Success as c_int
}

/// Free special tokens array
#[no_mangle]
pub unsafe extern "C" fn jikjoken_special_tokens_free(tokens: *mut *mut c_char, length: usize) {
    if !tokens.is_null() {
        let tokens_vec = Vec::from_raw_parts(tokens, length, length);
        for token_ptr in tokens_vec {
            if !token_ptr.is_null() {
                let _ = CString::from_raw(token_ptr);
            }
        }
    }
}

/// Get version information
#[no_mangle]
pub extern "C" fn jikjoken_version() -> *const c_char {
    static VERSION: &str = concat!(env!("CARGO_PKG_VERSION"), "\0");
    VERSION.as_ptr() as *const c_char
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        unsafe {
            let version = CStr::from_ptr(jikjoken_version());
            assert!(version.to_str().unwrap().starts_with("0.1."));
        }
    }
}
