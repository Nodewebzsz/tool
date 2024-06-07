const fs = require('fs');
const path = require('path');
const baseUrl = 'https://raw.githubusercontent.com/Nodewebzsz/tool/main/IconSet/';
function generateIconSetObject(folderPath,folderName) {
  const files = fs.readdirSync(folderPath);
  const imageArray = [];
  files.forEach(file => {
    const extname = path.extname(file);
    if (extname === '.png') { // 只处理 .png 图片
      const name = path.basename(file, extname); // 获取文件名 (不含扩展名)
      const url = baseUrl + folderName + '/' + file;
      console.log(url);
      imageArray.push({ name, url });
    }
  });
  // 创建包含图片数组的对象
  const iconSetObject = {
    name: folderName, // 自定义名称
    description: 'By Nodewebzsz', // 自定义描述
    icons: imageArray
  };
  return iconSetObject;
}
const folderPath = path.join(__dirname, 'IconSet');
fs.readdir(folderPath, (err, folders) => {
  if (err) {
    console.error(`Error reading folder: ${err.message}`);
    return;
  }
  folders
    .filter((folder) => fs.lstatSync(path.join(folderPath, folder)).isDirectory())
    .forEach((folder) => {
      const filePath = path.join(folderPath, folder);
      fs.writeFileSync(path.join(folderPath, `${folder}.json`), JSON.stringify(generateIconSetObject(filePath, folder), null, 2));
    });
});