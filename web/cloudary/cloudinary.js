/**
 * Cloudinary Frontend Helper cho Web (Thư mục: cloudary)
 */
export const CloudinaryConfig = {
  cloudName: 'fapcheckin',
  uploadPreset: 'fapcheckin_avatars',
  folder: 'cloudary',
};

export async function uploadAvatar(file, folder = CloudinaryConfig.folder) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', CloudinaryConfig.uploadPreset);
  formData.append('folder', folder);

  const res = await fetch(`https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload`, {
    method: 'POST',
    body: formData,
  });

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.error?.message || `HTTP ${res.status}`);
  }

  return await res.json();
}

