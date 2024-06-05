const fs = require('fs');
const path = require('path');

const folderPath = './IconSet/Color+'; // 请将这行替换为您的实际文件夹路径
const baseUrl = 'https://raw.githubusercontent.com/Nodewebzsz/tool/main/IconSet/Color+/';

function generateImageArray(folderPath, baseUrl) {
  const files = fs.readdirSync(folderPath);
  const imageArray = [];

  files.forEach(file => {
    const extname = path.extname(file);
    if (extname === '.png') { // 只处理 .png 图片
      const name = path.basename(file, extname); // 获取文件名 (不含扩展名)
      const url = baseUrl + file;
      imageArray.push({ name, url });
    }
  });

  return imageArray;
}

const imageArray = generateImageArray(folderPath, baseUrl);

// 创建包含图片数组的对象
const iconSetObject = {
    name: 'Color+', // 自定义名称
    description: 'By Nodewebzsz', // 自定义描述
    icons: imageArray
  };
  // 将对象转换为 JSON 字符串
const jsonString = JSON.stringify(iconSetObject, null, 2); // 2 表示缩进级别

// 写入 JSON 文件
fs.writeFileSync('Color+.json', jsonString);
console.log('Color+.json 文件已生成！');
// console.log(imageArray); // 输出生成的数组对象