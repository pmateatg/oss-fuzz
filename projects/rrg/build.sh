# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

compile_rust_fuzzer

rm -rf /out/disk_corpus || true
mkdir /out/disk_corpus
# Fat32 (2MB)
dd if=/dev/zero of=/out/disk_corpus/small_fat32.img bs=1M count=2
mkfs.vfat /out/disk_corpus/small_fat32.img

# ext4 (2MB)
dd if=/dev/zero of=/out/disk_corpus/small_ext4.img bs=1M count=2
mkfs.ext4 -F /out/disk_corpus/small_ext4.img
echo "Secret Content" > secret.txt
debugfs -w -R "mkdir /test_dir" /out/disk_corpus/small_ext4.img
debugfs -w -R "write secret.txt /test_dir/secret.txt" /out/disk_corpus/small_ext4.img

# NTFS (2MB)
dd if=/dev/zero of=/out/disk_corpus/small_ntfs.img bs=1M count=2
mkfs.ntfs -F -f /out/disk_corpus/small_ntfs.img

# MBR (2MB)
dd if=/dev/zero of=/out/disk_corpus/disk_mbr.img bs=1M count=2
echo "start=2048, type=83" | sfdisk /out/disk_corpus/disk_mbr.img