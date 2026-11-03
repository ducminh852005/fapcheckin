/**
 * Cấu hình Cloudinary cho Web Frontend (Admin & Staff Portal)
 */
export interface CloudinaryConfig {
  cloudName: string;
  uploadPreset: string;
  folder: string;
  apiKey?: string;
}

export const CLOUDINARY_CONFIG: CloudinaryConfig = {
  cloudName: (import.meta as any).env?.VITE_CLOUDINARY_CLOUD_NAME || 'fapcheckin',
  uploadPreset: (import.meta as any).env?.VITE_CLOUDINARY_UPLOAD_PRESET || 'fapcheckin_avatars',
  folder: (import.meta as any).env?.VITE_CLOUDINARY_FOLDER || 'cloudary',
  apiKey: (import.meta as any).env?.VITE_CLOUDINARY_API_KEY || '',
};

