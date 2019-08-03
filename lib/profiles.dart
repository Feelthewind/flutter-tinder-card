final List<Profile> demoProfiles = [
  new Profile(
    photos: [
      'https://cdn.pixabay.com/photo/2019/07/23/08/42/nature-4356963_960_720.jpg',
      'https://cdn.pixabay.com/photo/2015/06/25/17/56/people-821624_960_720.jpg',
      'https://cdn.pixabay.com/photo/2019/07/21/11/43/flowers-4352530_960_720.jpg',
      'https://cdn.pixabay.com/photo/2019/07/03/16/38/light-bulb-4314993_960_720.jpg',
    ],
    name: 'Someone Special',
    bio: 'This is the person you want!',
  ),
  new Profile(
    photos: [
      'https://cdn.pixabay.com/photo/2019/04/04/17/58/hong-kong-4103334_960_720.jpg',
      'https://cdn.pixabay.com/photo/2018/12/25/11/10/deer-3894103_960_720.png',
      'https://cdn.pixabay.com/photo/2019/05/20/19/43/recco-4217428_960_720.jpg',
      'https://cdn.pixabay.com/photo/2016/11/29/05/44/adult-1867608_960_720.jpg',
    ],
    name: 'Gross Person',
    bio: 'You better swipe left...',
  ),
  new Profile(
    photos: [
      'https://cdn.pixabay.com/photo/2019/07/28/13/52/snowdrop-4368752_960_720.jpg',
      'https://cdn.pixabay.com/photo/2016/11/15/08/20/big-ben-1825569_960_720.jpg',
      'https://cdn.pixabay.com/photo/2019/07/08/04/23/traveling-4323759_960_720.png',
      'https://cdn.pixabay.com/photo/2019/07/31/06/50/dog-4374473_960_720.jpg',
    ],
    name: 'Ooo Person',
    bio: 'You gogo',
  ),
];

class Profile {
  final List<String> photos;
  final String name;
  final String bio;

  Profile({
    this.photos,
    this.name,
    this.bio,
  });
}
