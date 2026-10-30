import { CLOUDINARY_CONFIG } from './cloudinaryConfig';

export interface CloudinaryUploadResponse {
  url: string;
  secureUrl: string;
  publicId: string;
  format: string;
  width?: number;
  height?: number;
  bytes?: number;
}

/**
 * Tải ảnh đại diện lên Cloudinary vào thư mục folder (mặc định: 'cloudary')
 * Dùng cho cả Web Admin và Web Portal.
 */
export async function uploadAvatarToCloudinary(
  file: File | Blob,
  options?: {
    folder?: string;
    uploadPreset?: string;
    cloudName?: string;
  }
): Promise<CloudinaryUploadResponse> {
  const cloudName = options?.cloudName || CLOUDINARY_CONFIG.cloudName;
  const uploadPreset = options?.uploadPreset || CLOUDINARY_CONFIG.uploadPreset;
  const folder = options?.folder || CLOUDINARY_CONFIG.folder;

  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', uploadPreset);
  formData.append('folder', folder);

  const endpoint = `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`;
  const res = await fetch(endpoint, {
    method: 'POST',
    body: formData,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error?.message || `Lỗi tải ảnh lên Cloudinary (${res.status})`);
  }

  const data = await res.json();
  return {
    url: data.url,
    secureUrl: data.secure_url,
    publicId: data.public_id,
    format: data.format,
    width: data.width,
    height: data.height,
    bytes: data.bytes,
  };
}

