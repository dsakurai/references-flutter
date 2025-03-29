function pickFile() {
    return new Promise((resolve, reject) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.onchange = (event) => {
        const file = event.target.files[0];
        if (!file) {
          reject('No file selected');
          return;
        }
        const reader = new FileReader();
        reader.readAsArrayBuffer(file);
        reader.onload = () => {
          resolve({
            name: file.name,
            size: file.size,
            type: file.type,
            data: Array.from(new Uint8Array(reader.result)),
          });
        };
        reader.onerror = (error) => reject(error);
      };
      input.click();
    });
  }
  